---

title: "Protobuf, Maven, M2E and Eclipse are on a boat"
date: 2011-12-25 19:30:45
comments: true
category:
- Maven
- m2e
- Protobuf
tags:
- java
- maven
- protobuf
- eclipse
- m2e
---
At [Days of Wonder](http://www.daysofwonder.com/) we develop several Java projects (for instance our online game servers).
Those are built with [Maven](http://maven.apache.org/), and most if not all are using [Google Protocol Buffers](http://code.google.com/p/protobuf/) for data interchange.

Development happens mostly in Eclipse, and until a couple of months ago with _m2eclipse_. With the release of [m2e](http://eclipse.org/m2e/) (m2eclipse successor), our builds don't work as is in Eclipse.

The reason is that we run the [maven-protoc-plugin](https://github.com/dtrott/maven-protoc-plugin) (the David Trott fork which is more or less now the only one available still seeing development). This maven plugins allows the ``protoc`` _Protocol Buffers_ compiler to be run at the ``generate-sources`` phase of the _Maven Lifecycle_. Under _m2eclipse_, this phase was happening outside _Eclipse_ and the builds was running fine. 

Unfortunately _m2e_ is not able to solve this correctly. It requires using a _connector_. Those _connectors_ are Eclipse plugins that ties a maven plugin to a m2e build lifecycle phase. This way when _m2e_ needs to execute this phase of the build, it can do so with the _connector_.

Until now, there wasn't any lifecycle connector for the maven-protoc-plugin. This wasn't possible to continue without this in the long term for our development team, so I took a stab to build it.

In fact it was way simpler than what I first thought. I used the [m2e Extension Development Guide](http://wiki.eclipse.org/M2E_Extension_Development) as a bootstrap (and especially the EGit extension).

The result of this few hours of development is now open-source and available in the [m2e-protoc-connector Github repository](https://github.com/masterzen/m2e-protoc-connector).

## Installation

I didn't release an Eclipse p2 update repository (mainly because I don't really know how to do that), so you'll have to build the project by yourself (but it's easy).

1. Clone the repository

```sh
git clone git://github.com/masterzen/m2e-protoc-connector.git
```

1. Build with maven 3

```sh
mvn package
```

Once built, you'll find the feature packaged in ``com.daysofwonder.tools.m2e-protoc-connector.feature/target/com.daysofwonder.tools.m2e-protoc-connector.feature-1.0.0.20111130-1035-site.zip``.

To install in Eclipse Indigo:

1. open the ``Install New Software`` window from the ``Help`` menu.
1. Then click on the ``Add`` button
1. select the ``Archive`` button and point it to the:
``com.daysofwonder.tools.m2e-protoc-connector.feature/target/com.daysofwonder.tools.m2e-protoc-connector.feature-1.0.0.20111130-1035-site.zip`` file.
1. Accept the license terms and restart eclipse.

## Usage

To use it there is no specific need, as long as your ``pom.xml`` conforms roughly to what we use:

```xml
    <plugin>
        <groupId>com.google.protobuf.tools</groupId>
        <artifactId>maven-protoc-plugin</artifactId>
        <executions>
            <execution>
                <id>generate proto sources</id>
                <goals>
                    <goal>compile</goal>
                </goals>
                <phase>generate-sources</phase>
                <configuration>
                    <protoSourceRoot>${basedir}/src/main/proto/</protoSourceRoot>
                    <includes>
                        <param>**/*.proto</param>
                    </includes>
                </configuration>
            </execution>
        </executions>
    </plugin>
...
  <dependency>
    <groupId>com.google.protobuf</groupId>
    <artifactId>protobuf-java</artifactId>
    <version>2.4.1</version>
  </dependency>
...
    <pluginRepositories>
        <pluginRepository>
            <id>dtrott-public</id>
            <name>David Trott's Public Repository</name>
            <url>http://maven.davidtrott.com/repository</url>
        </pluginRepository>
    </pluginRepositories>
```

If you find any problem, do not hesitate to open an issue on the [github repository](https://github.com/masterzen/m2e-protoc-connector).
