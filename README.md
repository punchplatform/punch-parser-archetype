# punch-parser-artefact

Quickstart generator to create your parser development project. 

On the punch you develop parsers as part of maven projects. A single project can contain
on or several so-called "parser". 

Each parser consists of :

* one or several punchlets. 
* optional grok patterns
* optional resource files

Together the punchlets parse, normalise and enrich incoming logs, whatever their format is. 

The punch comes equiped with many parsers. Should you write your own,
this project is for you. 

## Basics

To create punch parsers, clone or download this repository and simply execute 

```sh
mvn clean install
```

From there create your punch parsers maven project as follows: 

```sh
mvn archetype:generate \
	-DarchetypeGroupId=org.thales.punch \
	-DarchetypeArtifactId=parser \
	-DarchetypeVersion=1.0.0 \
	-DgroupId=com.mycompany \
	-DartifactId=parsers
```

Where of course you should replace 'com.mycompany' and 'parsers' with what suits you. 
If you execute the previous command you will get the following layout: 

```sh
├── assembly
│   └── assembly.xml
├── pom.xml
└── src
    └── com
        └── mycompany
            └── sample
                ├── MANIFEST.yml
                ├── groks
                │   └── pattern.grok
                ├── parser.punch
                ├── resources
                │   └── color_codes.json
                └── test
                    └── unit.json
```

Where

* 'com/mycompany/parsers/sample' is a fully qualified name of your parsers. That will be the way to uniquely identify, and deploy your parsers on a production punch.
* 'com/mycompany/parsers/sample/parser.punch' is a sample punch parser. Check it out it illustrates the basics.
 This is where you write the actual logic of your parsers.
* 'com/mycompany/parsers/sample/groks/pattern.grok' is a sample grok pattern. The punch comes with many patterns directlt loaded, but here is how you can add your own.
* 'com/mycompany/parsers/sample/resources/polor_codes.json' is a sample resource files. This lets you enrich logs or design fully generic punchlets. In this cas it is used to add a numerical color code froma  color string value ('red' or 'green').
* 'com/mycompany/parsers/sample/test/unit.json' is a punch unit test file. That lets you define unit test to ensure your parser if correctly tested before being deployed. 

In short, you have everything to easily code, test and package and deploy your parsers.

## Understand Punch Parsers Archives

Here is the logic. First note that this layout is designed to hold one or several parsers.
Each 'parser' is a set of punchlets, groks and resources that take care of some
data transformation, normalisationa nd enrichment. 

You are free to create one parser project per log type of vendor (i.e. cisco, sourcefire,
linux etc..). The only drawback is that you might end up with many projects. 
Hence the facility to deal with a single project to hold several of your parsers. 

Let us consider an example. First let us describe how you will refer to your punchlets in data pipeline. 
If you install the above com.mycompany.parsers:1.0.0 package to a punchplatform, you will be able to refer to

```sh
  com/mycompany/sample/parser.punch
```

in your data pipelines. As simple as that. That basic mechanism ensure you r parsers will be worldwide unique.

Coming back to the grouping of several punchlets as part of a parser, and several parsers as part of 
parser archive here is the rationale: the punch is designed to help you write modular functions. You can provide
generic functions (say to deal with the very first syslog header of your logs or to enrich your logs with geoip data)
that you might want to execute in front of after every other vendor specific function. You typically would like
to have the following chain of functions applied to each incoming 'cisco' log:

```sh
  com/mycompany/common/header.punch
  com/mycompany/cisco/parser.punch
  com/mycompany/cisco/enrich.punch
  com/mycompany/common/geoip.punch
```

To achieve that you can package in your parser archive two sub-parsers: one 'common', and one 'cisco'.

Whatever you decide to do, each parser (in the above example 'sample', or 'cisco or 'common' in our last example)
is defined using a 'MANIFEST.yaml' file. 

That file defines the essential information about the parser. Here the sample MANIFEST.yaml generated above:

```yaml
version: 1.0
name: "sample punch parser"
description: "sample log parser description"
tags:
- web  
author: dimi
performance: 10000
vendor: vendor
punchlets:
- common/common.punch
- common/geoip.punch
```

## Package Your Parser

Go to the 'parsers' folder and simply type in: 

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
- meta: com.mycompany:parsers:1.0.0
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
    - com/mycompany/sample/resources/color_codes.json
    punchlets:
    - com/mycompany/sample/parser.punch
  subscribe:
  - component: syslog_input
    stream: logs
```
