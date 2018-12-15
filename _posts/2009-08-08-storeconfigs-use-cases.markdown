--- 

title: Storeconfigs (advanced) use cases
date: 2009-08-08 12:49:59 +02:00
comments: true
wordpress_id: 85
wordpress_url: http://www.masterzen.fr/?p=85
category: 
- System Administration
- Puppet
tags: 
- puppet
- storeconfigs
- storedconfigs
---
This week on [#puppet](http://reductivelabs.com/trac/puppet/wiki/IrcChannel), [Nico](http://www.rottenbytes.info/) asked for a [storeconfigs](http://reductivelabs.com/trac/puppet/wiki/UsingStoredConfiguration) live example. So I thought, a blog post would be perfect to post an example of a _storeconfigs_ use case and its full explanation. Of course if you're interested in some discussions around storeconfigs, please report to the following blog posts:

- [All about storeconfigs](http://www.masterzen.fr/2009/03/08/all-about-puppet-storeconfigs/)
- [OMG!!! Storeconfigs killed my database](http://www.masterzen.fr/2009/03/18/omg-storedconfigs-killed-my-database/)


At [Days of Wonder](http://www.daysofwonder.com), I use _storeconfigs_ for only one type of use: **exchanging information between nodes**. But I know some other people use this feature as an **inventory system** (to know what node gets what configuration).

## Use case 1: website document root replication

Let's start with a simple example, easily understandable.

At Days of Wonder we have a bunch of webservers arranged in a kind of cluster. All these webservers document root (where reside the various php and image files) should be always in sync. So we rsync to all webservers, from a central build server each time the developpers commit a change.

The tedious part with this scheme is that you have to make sure all the webservers have the correct ssh authorized_keys and ssh authorization for the build server to contact them successfully.

#### The manifest

``` ruby

# Class:: devl
# This class is implemented on the build server
#
# Usage:
# Generate a ssh key and store the private key and public key
# on the puppetmaster files mount as keys/buildkey and keys/buildkey.pub
#
#   node build {
#       include devl
#       devl::pushkey{
#           "build":
#               keyfile => "files/keys/buildkey"
#       }
#   }
#
#
class devl {
    ...
    define pushkey($keyfile) {
        @@ssh_authorized_key {
            "push-${name}@${fqdn}":
                user => "push",
                type => "ssh-rsa",
                tag => "push",
                # this is to remove the ssh-rsa prefix, the suffix and trim any \n
                key => gsub(gsub(file("/etc/puppet/${keyfile}.pub"), '^ssh-rsa (.*) .*$', '\1'), "\n", ""),
                options => ['command="rsync --server -vlgDtpr --delete . /path/to/docroot/"', 'no-port-forwarding','no-X11-forwarding','no-agent-forwarding','no-pty'],
        }

        # store the private key locally, for our rsync build
        file {
            "/home/build/.ssh/id_${name}":
                ensure => file, owner => "build", group => "build",
                source => "puppet:///${keyfile}", mode => 0400,
                alias => "pkey-${name}",
                require => [User["build"], File["/home/build/.ssh"]]
        }
    }
    ...
}

# Class: www::push
# This class is implemented on webservers
#
class www::push {
    ... create here the push user and so on...
    Ssh_authorized_key <<| tag == "push" |>>
    ...
}
[/sourcecode]
```

#### Inner workings


It's easy when the build server applies its configuration, it creates an exported ssh_authorized_key (notice the double @), which is not applied locally. Instead it is stored in the storeconfigs database.

We also create locally a file containing the ssh private key pair.

When one of the webserver comes to check out its configuration, it implements the www::push class which collects all ssh_authorized_key resources tagged with "push".

That is all the authorized keys we created with the pushkey definition in the build configuration. The collection means that this resource is created as if we defined it in the node that collects it. That means the webserver will have a new ssh authorized key whose action, options and keys are the one defined in the build server configuration.

Of course this manifest doesn't show everything, it also drops a handful of shell scripts to do the rsync using the local private keys, along with more configuration files for some other parts of the build.

Note: the gsub function is a custom parser function I borrowed from [David Schmidtt](http://dasz.at/) repository. In 0.25 it would be replaced by regsubst.

## Use case 2: tinydns master and slaves

Once again at Days of Wonder, we run [tinydns](http://cr.yp.to/djbdns.html) as our DNS server. _Tinydns_ doesn't have a fancy full of security holes zone transfer system, so we emulate this functionality by rsync'ing the zone files from the master to the slaves each time the zones are changed (the zones are managed by Puppet of course).

This is somehow the exact same system as the one we saw in the **use case 1**, except there is one key for all the slaves, and more important **each slave registers itself to the master** to be part of the replication.

#### The manifest

``` ruby
class djbdns {
    ...

    # Define: tinydns::master
    # define a master with its listening +ip+, +keyfile+, and zonefile.
    # Usage:
    #     djbdns::tinydns::master {
    #         "root":
    #             keyfile => "files/keys/tinydns",
    #             content => "files/dow/zone"
    #     }
    #
    define tinydns::master($ip, $keyfile, $content='') {
        $root = "/var/lib/service/${name}"
        tinydns::common { $name: ip => $ip, content=>$content }

        # send our public key to our slaves
        @@ssh_authorized_key {
            "dns-${name}@${fqdn}":
                user => "root",
                type => "ssh-rsa",
                tag => "djbdns-master",
                key => file("/etc/puppet/${keyfile}.pub"),
                options => ["command=\"rsync --server -logDtprz . ${root}/root/data.cdb\"", "from=\"${fqdn}\"", 'no-port-forwarding','no-X11-forwarding','no-agent-forwarding','no-pty']
        }

        # store our private key locally
        file {
            "/root/.ssh/${name}_identity":
            ensure => file,
            source => "puppet://${keyfile}", mode => 0600,
            alias => "master-pkey-${name}"
        }

        # replicate with the help of the propagate-key script
        # this exec subscribe to the zone file and the slaves
        # which means each time we add a slave it is rsynced
        # or each time the zone file changes.
        exec {
            "propagate-data-${name}":
                command => "/usr/local/bin/propagate-key ${name} /var/lib/puppet/modules/djbdns/slaves.d /root/.ssh/${name}_identity",
                subscribe => [File["/var/lib/puppet/modules/djbdns/slaves.d"] , File["${root}/root/data"], Exec["data-${name}"]],
                require => [File["/usr/local/bin/propagate-key"], Exec["data-${name}"]],
                refreshonly => true
        }

        # collect slaves address
        File<<| tag == 'djbdns' |>>
    }

    # Define:: tinydns::slave
    # this define is implemented on each tinydns slaves
    define tinydns::slave($ip) {
        $root = "/var/lib/service/${name}"

        tinydns::common { $name: ip => $ip }

        # publish our addresses back to the master
        # our ip address ends up being in a file name in the slaves.d directory
        # where the propagate-key shell script will get it.
        @@file {
            "/var/lib/puppet/modules/djbdns/slaves.d/${name}-${ipaddress}":
            ensure => file, content => "\n",
            alias => "slave-address-${name}",
            tag => 'djbdns'
        }

        # collect the ssh public keys of our master
        Ssh_authorized_key <<| tag == 'djbdns-master' |>>
    }
}
```

#### Inner workings

This time we have a double exchange system:

1.  The master exports its public key to be collected by the slaves
2. and the slaves are exporting back their IP addresses to the master, under the form a of an empty file. Their IP address is encoded in those file names.


When the zone file has to be propagated, the propagate-key shell script is executed. This script lists all the file in the /var/lib/puppet/djbdns/slaves.d folder where the slaves exports their ip addresses, extract the ip address from the file names and calls rsync with the correct private key. Simple and elegant, isn't it?

## Other ideas

There's simply no limitation to what we can do with storeconfigs, because you can export any kind of resources, not only files or ssh authorized keys.

I'm giving here some ideas (some that we are implementing here):

- Centralized backups. Using rdiff-backup for instance, we could propagate the central backup server key to all servers, and get back the list of files to backup.
- Resolv.conf building. This is something we're doing at Days of Wonder. Each dnscache server exports their IP address, and we build resolv.conf on each host from those addresses.
- Ntp automated configuration: each NTP server (of a high stratum) exports their ip address (or ntp.conf configuration fragments) that can be used for all the other NTP server to be pointed to those to form lower stratum servers.
- Automated monitoring configurations: each service and node exports configuration fragments that are collected on the NMS host to build the NMS configuration. People running nagios or munin seems to do that.


If you have some creative uses of storeconfigs, do not hesitate to publish them, either on the Puppet-user list, the Puppet wiki or elsewhere (and why not in a blog post that could be aggregated by [Planet Puppet](http://www.planetpuppet.org/)).
