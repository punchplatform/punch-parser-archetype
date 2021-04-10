# punch-parser-artefact

Quickstart generator to create your organisation parsers. 

A parser is a package made of one or several punchlets, resource files and test files.
Alltogether a parser can be deployed to completely parse, normalise and enrich 
incoming logs, whatever their format is. 

The punch comes equipped with many parsers. Should you write your own,
this project is for you. 

## Basics

To create punch parsers, clone or download this repository and simply execute 

```sh
mvn clean install
```

From there you can easily create your punch parsers maven project as follows: 

```sh
mvn archetype:generate \
	-DarchetypeGroupId=org.thales.punch \
	-DarchetypeArtifactId=parser \
	-DarchetypeVersion=1.0.0 \
	-DgroupId=com.mycompany \
	-DartifactId=myparsers
```

Where of course you should replace 'com.mycompany' and 'myparsers' with what suits you. 



If you execute the previous command you will get the following layout: 

```sh
myparsers
├── assembly
│   └── assembly.xml
├── pom.xml
└── src
    └── com
        └── mycompany
            ├── common
            │   ├── MANIFEST.yml
            │   ├── common.punch
            │   └── test
            │       └── unit.json
            └── vendor
                ├── MANIFEST.yml
                ├── parsing.punch
                ├── resources
                │   └── resource.json
                └── test
                    └── unit.json
```

## Understand Punch Parsers

Here is the logic. First note that this layout is designed to hold one or several parsers. 
You are free to create one parser project per log type of vendor (i.e. cisco, sourcefire,
linux etc..). The only drawback is that you might end up with many projects. 
Hence the facility to deal with a single project to hold several of your parsers. 

In addition, the punch is designed to help you write modular functions. 
In the example above the 'common' folder is an example of the way to define a common
function 'common.punch' (say to deal with the very first syslog header of your logs)
that you might want to execute in front of every other vendor specific function. 

Whatever you decide to do, each parser is defined using a 'MANIFEST.yaml' file. That file 
defines the essential information about the parser. Here the sample MANIFEST.yaml generated above:

```yaml
version: 1.0
name: "sample punch parser"
description: "sample log parser description"
tags:
- web  
author: dimi
performance: 10000
vendor: vendor
structure:
- common/common.punch
- vendor/parsing.punch
```

Note that this parser expects to be always preceeded by the 'common/common.punch' 
parser. 

## Package Your Parser

Go to the 'myparsers' folder and simply type in: 

```sh
mvn clean install
```

That will test then generate your parser package in 'target/myparsers-1.0-SNAPSHOT.zip'.
That zip file is the one you can upload or publish to the punch marketplace or to your production 
punch. 


## Using Your Parsers

Once your parser are deployed, you can simply refer to them in your punchline. 
Remember a punchline is a log processing pipeline where you chain your parser. 

An example explains it all: 

```yaml
version: "7.0"
name: dhcp-parser
runtime: storm
resources:
- path: myparser-1.0-SNAPSHOT.zip
dag:
- type: syslog_input
  settings:
    listen:
      proto: tcp
      host: 0.0.0.0
      port: 9902
  publish:
  - stream: logs
    fields:
    - log
- type: punchlet_node
  settings:
    json_resources:
    - com/mycompany/vendor/resources.json
    punchlets:
    - com/mycompany/common/common.punch
    - com/mycompany/vendor/parsing.punch
  subscribe:
  - component: syslog_input
    stream: logs
``

