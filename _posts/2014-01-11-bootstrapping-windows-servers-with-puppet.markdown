---

title: "Bootstrapping Windows servers with Puppet"
date: 2014-01-11 17:45
comments: true
categories: 
  - puppet
  - devops
  - sysadmin
tags: 
  - puppet
  - devops
---

All started a handful of months ago, when it appeared that we'd need to build some of our [native software on Windows](). Before that time, all our desktop software at [Days of Wonder]() was mostly cross-platform java code that could be cross-compiled on Linux. Unfortunately, we badly needed a Windows build machine.

In this blog post, I'll tell you the whole story from my zero knowledge of Windows administration to an almost fully automatized Windows build machine image construction.

## Jenkins

But, first let's digress a bit to explain in which context we operate our builds.

Our CI system is built around Jenkins, with a specific twist. We run the Jenkins master on our own infrastructure and our build slaves on AWS EC2. The reason behind this choice is out of the scope of this article (but you can still ask me, I'll happily answer). 

So, we're using the [Jenkins EC2 plugin](), and a [revamped by your servitor Jenkins S3 Plugin](). We produce somewhat large binary artifacts when building our client software, and the bandwidth between EC2 and our master is not that great (and expensive), so using the aforementioned patch I contributed, we host all our artifacts into S3, fully managed by our out-of-aws Jenkins master.

The problem I faced when starting to explore the intricate world of Windows in relation with Jenkins slave, is that we wanted to keep the Linux model we had: on-demand slave spawned by the master when scheduling a build. Unfortunately the current state of the Jenkins EC2 plugin only supports Linux slave.

## Enter WinRM and WinRS

The EC2 plugin for Linux slave works like this:

1. it starts the slave
1. using an internal scp implementation it copies 'slave.jar' which implements the [client Jenkins remoting protocol]()
1. using an internal ssh implementation, it executes `java -jar slave.jar`.
   The stdin and stdout of the slave.jar process is then connected to the jenkins master through an ssh tunnel.
1. now, Jenkins does its job (basically sending more jars, classes)
1. at this stage the slave is considered up

I needed to replicate this behavior. In the Windows world, ssh is inexistent. You can find some native implementation (like FreeSSHd or some other commercial ones), but all that options weren't easy to implement, or simply non-working.

In the Windows world, remote process execution is achieved through the [Windows Remote Management](http://msdn.microsoft.com/en-us/library/aa384426%28v=vs.85%29.aspx) which is called _WinRM_ for short. _WinRM_ is an implementation of the WSMAN specifications. It allows to access the [Windows Management Instrumentation](https://en.wikipedia.org/wiki/Windows_Management_Instrumentation) to get access to hardware counters (ala SNMP or IPMI for the unix world).

One component of WinRM is _WinRS_: _Windows Remote Shell_. This is the part that allows to run remote commands. Recent Windows version (at least since Server 2003) are shipped with WinRM installed (but not started by default).

WinRM is an HTTP/SOAP based protocol. By default, the payload is encrypted if the protocol is used in a Domain Controller environment (in this case, it uses Kerberos), which will not be our case on EC2.

Digging, further, I found two client implementations:

- [Xebialabs Overthere](https://github.com/xebialabs/overthere) written in Java
- [WinRb](https://github.com/WinRb/WinRM), written in Ruby.

I started integrating Overthere into the ec2-plugin but encountered several incompatibilities, most notably Overthere was using a more recent dependency on some libraries than jenkins itself.

I finally decided to create my own WinRM client implementation and released [Windows support for the EC2 plugin](https://github.com/jenkinsci/ec2-plugin/pull/67). This hasn't been merged upstream, and should still be considered experimental.

We're using this version of the plugin for about a couple of month and it works, but to be honest WinRM doesn't seem to be as stable as ssh would be. There are times the slave is unable to start correctly because WinRM abruptly stops working (especially shortly after the machine boots).

## WinRM, the bootstrap

So all is great, we know how to execute commands remotely from Jenkins. But that's not enough for our _sysadmin_ needs. Especially we need to be able to create a Windows AMI that contains all our software to build our own applications.

Since I'm a long time Puppet user (which you certainly noticed if you read this blog in the past), using Puppet to configure our Windows build slave was the only possiblity. So we need to run Puppet on a Windows base AMI, then create an AMI from there that will be used for our build slaves. And if we can make this process repeatable and automatic that'd be wonderful.

In the Linux world, this task is usually devoted to tools like [Packer](http://packer.io/) or [Veewee](https://github.com/jedi4ever/veewee) (which BTW supports provisioning Windows machines). Unfortunately Packer which is written in Go doesn't yet support Windows, and Veewee doesn't support EC2.

That's the reason I ported the small implementation I wrote for the Jenkins EC2 plugin to a [WinRM Go library](https://github.com/masterzen/winrm). This was the perfect pet project to learn a new language :)

## Windows Base AMI

So, starting with all those tools, we're ready to start our project. But there's a caveat: WinRM is not enabled by default on Windows. So before automating anything we need to create a Windows base AMI that would have the necessary tools to further allow automating installation of our build tools.

### Windows boot on EC2

There's a service running on the AWS Windows AMI called [EC2config](https://aws.amazon.com/developertools/5562082477397515) that does the following at the first boot:

1. set a random password for the 'Administrator' account
1. generate and install the host certificate used for Remote Desktop Connection.
1. execute the specified user data (and cloud-init if installed)

On first and subsequent boot, it also does:

1. it might set the computer host name to match the private DNS name 
1. it configures the key management server (KMS), check for Windows activation status, and activate Windows as necessary.
1. format and mount any Amazon EBS volumes and instance store volumes, and map volume names to drive letters.
1. some other administrative tasks

One thing that is problematic with Windows on EC2 is that the Administrator password is unfortunately defined randomly at the first boot. That means to further do things on the machine (usually using remote desktop to administer it) you need to first know it by asking AWS (with the command-line you can do: `aws ec2 get-password-data`).

Next, we might also want to set a custom password instead of this dynamic one. We might also want to enable WinRM and install several utilities that will help us later.

To do that we can inject specific AMI `user-data` at the first boot of the Windows base AMI. Those user-data can contain one or more cmd.exe or Powershell scripts that will get executed at boot.

I created this [Windows bootstrap Gist](https://gist.github.com/masterzen/6714787) (actually I forked and edited the part I needed) to prepare the slave.

### First bootstrap

First, we'll create a Windows security group allowing incoming WinRM, SMB and RDP:

```bash
aws ec2 create-security-group --group-name "Windows" --description "Remote access to Windows instances"
# WinRM
aws ec2 authorize-security-group-ingress --group-name "Windows" --protocol tcp --port 5985 --cidr <YOURIP>/32
# Incoming SMB/TCP 
aws ec2 authorize-security-group-ingress --group-name "Windows" --protocol tcp --port 445 --cidr <YOURIP>/32
# RDP
aws ec2 authorize-security-group-ingress --group-name "Windows" --protocol tcp --port 3389 --cidr <YOURIP>/32
```

Now, let's start our base image with the following user-data (let's put it into userdata.txt):

```xml
<powershell>
Set-ExecutionPolicy Unrestricted
icm $executioncontext.InvokeCommand.NewScriptBlock((New-Object Net.WebClient).DownloadString('https://gist.github.com/masterzen/6714787/raw')) -ArgumentList "VerySecret"
</powershell>
```
This powershell script will download the [Windows bootstrap Gist](https://gist.github.com/masterzen/6714787) and execute it, passing the desired administrator password.


Next we launch the instance:
```bash
aws ec2 run-instances --image-id ami-4524002c --instance-type m1.small --security-groups Windows --key-name <YOURKEY> --user-data "$(cat userdata.txt)"
```

Unlike what is written in the [ec2config documentation](http://docs.aws.amazon.com/AWSEC2/latest/WindowsGuide/UsingConfig_WinAMI.html), the user-data must not be encoded in Base64.

Note, the first boot can be quite long :)

After that we can connect through WinRM with the "VerySecret" password. To check we'll use the WinRM Go tool I wrote and talked about above:

```bash
./winrm -hostname <publicip> -username Administrator -password VerySecret "ipconfig /all"
```
We should see the output of the ipconfig command.

_Note_: in the next winrm command, I've omitted the various credentials to increase legibility (a future version of the tool will allow to read a config file, meanwhile we can create an alias).

A few caveats:

- BITS doesn't work in the user-data powershell, because it requires a user to be logged-in which is not possible during boot, that's the reason downloading is done through the `System.Net.WebClient`
- WinRM enforces some resource limits, you might have to increase the allowed shell resources for running some hungry commands:
  `winrm set winrm/config/winrs @{MaxMemoryPerShellMB="1024"}`
  Unfortunately, this is completely broken in Windows Server 2008 unless you [install this Microsoft hotfix](http://support.microsoft.com/kb/2842230)
  The linked bootstrap code doesn't install this hotfix, because I'm not sure I can redistribute the file, that's an exercise left to the reader :)
- the winrm traffic is **not encrypted nor protected** (if you use my tool). Use at your own risk. It's possible to setup WinRM over HTTPS, but it's a bit more involved. Current version of my WinRM tool doesn't support HTTPS yet (but it's very easy to add).

### Baking our base image

Now that we have our base system with WinRM and Puppet installed by the bootstrap code, we need to create a derived AMI that will become our base image later when we'll create our different windows machines.

```bash
aws ec2 create-image --instance-id <ourid> --name 'windows-2008-base'
```

For a real world example we might have defragmented and blanked the free space of the root volume before creating the image (on Windows you can use `sdelete` for this task). 

Note that we don't run the Ec2config sysprep prior to creating the image, which means the first boot of any instances created from this image won't run the whole boot sequence and our Administrator password will not be reset to a random password.

## Where does Puppet fit?

Now that we have this base image, we can start deriving it to create other images, but this time using Puppet instead of a powershell script. Puppet has been installed on the base image, by virtue of the powershell bootstrap we used as user-data.

First, let's get rid of the current instance and run a fresh one coming from the new AMI we just created:

```bash
aws ec2 run-instances --image-id <newami> --instance-type m1.small --security-groups Windows --key-name <YOURKEY>
```

### Anatomy of running Puppet

We're going to run Puppet in masterless mode for this project. So we need to upload our set of manifests and modules to the target host.

One way to do this is to connect to the host with SMB over TCP (which our base image supports):

```bash
sudo mkdir -p /mnt/win
sudo mount -t cifs -o user="Administrator%VerySecret",uid="$USER",forceuid "//<instance-ip>/C\$/Users/Administrator/AppData/Local/Temp" /mnt/win
```

Note how we're using an Administrative Share (the `C$` above). On Windows the Administrator user has access to the local drives through Administrative Shares without having to _share_ them as for normal users.

The user-data script we ran in the base image opens the windows firewall to allow inbound SMB over TCP (port 445).

We can then just zip our manifests/modules, send the file over there, and unzip remotely:

```bash
zip -q -r /mnt/win/puppet-windows.zip manifests/jenkins-steam.pp modules -x .git
./winrm "7z x -y -oC:\\Users\\Administrator\\AppData\\Local\\Temp\\ C:\\Users\\Administrator\\AppData\\Local\\Temp\\puppet-windows.zip | FIND /V \"ing  \""
```

And finally, let's run Puppet there:
```bash
./winrm "\"C:\\Program Files (x86)\\Puppet Labs\\Puppet\\bin\\puppet.bat\" apply --debug --modulepath C:\\Users\\Administrator\\AppData\\Local\\Temp\\modules C:\\Users\\Administrator\\AppData\\Local\\Temp\\manifests\\site.pp"
```

And voila, shortly we'll have a running instance configured. Now we can create a new image from it and use it as our Windows build slave in the ec2 plugin configuration.

## Puppet on Windows

Puppet on Windows is not like your regular Puppet on Unix. Let's focus on what works or not when running Puppet on Windows.

### Core resources known to work

The obvious ones known to work:

- ___File___: beside symbolic links that are supported only on Puppet >3.4 and Windows 2008+, there are a few things to take care when using files:
    + NTFS is case-insensitive (but not the file resource namevar)
    + Managing permissions: octal unix permissions are mapped to Windows permissions, but the translation is imperfect. Puppet    doesn't manage Windows ACL (for more information check [Managing File Permissions on Windows](http://docs.puppetlabs.com/windows/writing.html#managing-file-permissions))

- ___User___: Puppet can create/delete/modify local users. The Security Identifier (SID) can't be set. User names are case-insensitive on Windows. To my knowledge you can't manage domain users.

- ___Group___: Puppet can create/delete/modify local groups. Puppet can't manage domain groups.

- ___Package___: Puppet can install MSI or exe installers present on a local path (you need to specify the source). For a more comprehensive package system, check below the paragraph about Chocolatey.

- ___Service___: Puppet can start/stop/enable/disable services. You need to specify the short service name, not the human-reading service name.

- ___Exec___: Puppet can run executable (any .exe, .com or .bat). But unlike on Unix, there is no shell so you might need to wrap the commands with `cmd /c`. Check the [Powershell exec provider module](http://forge.puppetlabs.com/joshcooper/powershell) for a more comprehensive Exec system on Windows.

- ___Host___: works the same as for Unix systems.

- ___Cron___: there's no cron system on Windows. Instead you must use the [Scheduled_task](http://docs.puppetlabs.com/references/latest/type.html#scheduledtask) type.


### Do not expect your average unix module to work out-of-the-box

Of course that's expected, mostly because of the used packages. Most of the Forge module for instance are targeting unix systems. Some Forge modules are Windows only, but they tend to cover specific Windows aspects (like registry, Powershell, etc...), still make sure to check those, as they are invaluable in your module Portfolio.

### My Path is not your Path!

You certainly know that Windows paths are not like Unix paths. They use `\` where Unix uses `/`.

The problem is that in most languages (including the Puppet DSL) '\' is considered as an escape character when used in double quoted strings literals, so must be doubled `\\`.

Puppet single-quoted strings don't understand all of the escape sequences double-quoted strings know (it only parses `\'` and `\\`), so it is safe to use a lone `\` as long as it is not the last character of the string. 

Why is that?

Let's take this path `C:\Users\Administrator\`, when enclosed in a single-quoted string `'C:\Users\Administrator\'` you will notice that the last 2 characters are `\'` which forms an escape sequence and thus for Puppet the string is not terminated correctly by a single-quote.
The safe way to write a single-quoted path like above is to double the final slash: `'C:\Users\Administrator\\'`, which looks a bit strange. My suggestion is to double all `\` in all kind of strings for simplicity.

Finally when writing an [UNC Path](http://en.wikipedia.org/wiki/Path_(computing)#UNC_in_Windows) in a string literal you need to use four backslashes: `\\\\host\\path`.

Back to the slash/anti-slash problem there's a simple rule: if the path is directly interpreted by Puppet, then you can safely use `/`. If the path if destined to a Windows command (like in an Exec), use a `\`.

Here's a list of possible type of paths for Puppet resources:

- _Puppet URL_: this is an url, so `/`
- _template paths_: this is a path for the master, so `/`
- _File path_: it is preferred to use `/` for coherence
- _Exec command_: it is preferred to use `/`, but beware that most Windows executable requires `\` paths (especially `cmd.exe`)
- _Package source_: it is preferred to use `/`
- _Scheduled task command_: use `\` as this will be used directly by Windows.


### Windows facts to help detection of windows

To identify a Windows client in a Puppet manifests you can use the `kernel`, `operatingsystem` and `osfamily` facts that all resolves to `windows`.

Other facts, like `hostname`, `fqdn`, `domain` or `memory*`, `processorcount`, `architecture`, `hardwaremodel` and so on are working like their Unix counterpart.

Networking facts also works, but with the Windows Interface name (ie `Local_Area_Connection`), so for instance the local ip address of a server will be in `ipaddress_local_area_connection`. The `ipaddress` fact also works, but on my Windows EC2 server it is returning a link-local IPv6 address instead of the IPv4 Local Area Connection address (but that might because it's running on EC2).

### Do yourself a favor and use Chocolatey

We've seen that Puppet _Package_ type has a Windows provider that knows how to install MSI and/or exe installers when provided with a local _source_. Unfortunately this model is very far from what Apt or Yum is able to do on Linux servers, allowing access to multiple repositories of software and on-demand download and installation (on the same subject, we're still missing something like that for OSX).

Hopefully in the Windows world, there's [Chocolatey](http://chocolatey.org/). Chocolatey is a package manager (based on NuGet) and a public repository of software (there's no easy way to have a private repository yet). If you read the bootstrap code I used earlier, you've seen that it installs Chocolatey.

Chocolatey is quite straightforward to install (beware that it doesn't work for Windows Server Core, because it is missing the shell Zip extension, which is the reason the bootstrap code installs Chocolatey manually).

Once installed, the `chocolatey` command allows to install/remove software that might come in several flavors: either _command-line_ packages or _install_ packages. The first one only allows access through the command line, whereas the second does a full installation of the software.

So for instance to install Git on a Windows machine, it's as simple as:

```bash
chocolatey install git.install
```

To make things much more enjoyable for the Puppet users, there's a [Chocolatey Package Provider Module](http://forge.puppetlabs.com/rismoney/chocolatey) on the Forge allowing to do the following

```ruby
package {
  "cmake":
    ensure => installed,
    provider => "chocolatey"
}
```

Unfortunately at this stage it's not possible to host easily your own chocolatey repository. But it is possible to host your own chocolatey packages, and use the `source` metaparameter. In the following example we assume that I packaged cmake version 2.8.12 (which I did by the way), and hosted this package on my own webserver:

```ruby
# download_file uses powershell to emulate wget
# check here: http://forge.puppetlabs.com/opentable/download_file
download_file { "cmake":
  url                   => "http://chocolatey.domain.com/packages/cmake.2.8.12.nupkg",
  destination_directory => "C:\\Users\\Administrator\\AppData\\Local\\Temp\\",
}
->
package {
  "cmake":
    ensure => install,
    source => "C:\\Users\\Administrator\\AppData\\Local\\Temp\\"
}
```

You can also decide that chocolatey will be the default provider by adding this to your site.pp:

```ruby
Package {
  provider => "chocolatey"
}
```

Finally read [how to create chocolatey packages](https://github.com/chocolatey/chocolatey/wiki/CreatePackages) if you wish to create your own chocolatey packages.

### Line endings and character encodings

There's one final things that the Windows Puppet user must take care about. It's line endings and character encodings.
If you use Puppet _File_ resources to install files on a Windows node, you must be aware that file content is transferred verbatim from the master (either by using `content` or `source`).

That means if the file uses the Unix `LF` line-endings the file content on your Windows machine will use the same.
If you need to have a Windows line ending, make sure your file on the master (or the content in the manifest) is using Windows `\r\n` line ending.

That also means that your text files might not use a windows character set. It's less problematic nowadays than it could have been in the past because of the ubiquitous UTF-8 encoding. But be aware that the default character set on western Windows systems is [CP-1252](http://en.wikipedia.org/wiki/Windows-1252) and not UTF-8 or ISO-8859-15. It's possible that `cmd.exe` scripts not encoded in CP-1252 might not work as intended if they use characters out of the ASCII range.

## Conclusion

I hope this article will help you tackle the hard task of provisioning Windows VM and running Puppet on Windows. It is the result of several hours of hard work to find the tools and learn Windows knowledge.

During this journey, I started learning a new language (Go), remembered how I dislike Windows (and its administration), contributed to several open-source projects, discovered a whole lot on Puppet on Windows, and finally learnt a lot on WinRM/WinRS.

Stay tuned on this channel for more article (when I have the time) about Puppet, programming and/or system administration :)
