# punch-parser-archetype

Quickstart generator to create your parser development project. 

On the punch you develop parsers as part of maven projects. A single project can contain
on or several groups. Each group consists of :

* one or several punchlets. 
* optional grok patterns
* optional resource files
* optional unit and sample test files

Together the punchlets parse, normalise and enrich the incoming logs, whatever their format is. 

The punch comes equiped with many parsers. Should you write your own, this project is for you. 

## Basics

To create punch parsers, clone or download this repository, 
go to that directory and simply execute 

```sh
mvn clean install
```

From there leave that directory and in some folder that suits you,  create your new punch maven project as follows: 

```sh
mvn archetype:generate \
    -DarchetypeCatalog=local \
	-DarchetypeGroupId=com.thalesgroup.punchplatform \
	-DarchetypeArtifactId=punch-parser-archetype \
	-DarchetypeVersion=1.0.0 \
	-DgroupId=com.mycompany \
	-DartifactId=my-punch-parser
```

Where of course you should replace 'com.mycompany' and 'my-punch-parser' with what suits you. 
If you execute the previous command you will get the following layout: 

```sh
.
├── assembly
│   ├── assembly-artifact.xml
│   └── assembly-src.xml
├── metadata
│   └── metadata.yml
├── pom.xml
├── src
│   └── com
│       └── mycompany
│           └── sample
│               ├── MANIFEST.yml
│               ├── README.md
│               ├── enrich.punch
│               ├── groks
│               │   └── pattern.grok
│               ├── parser.punch
│               ├── resources
│               │   └── color_codes.json
│               └── test
│                   ├── sample.txt
│                   └── unit.json
└── tools
    └── test.sh
```

Where:

* 'com/mycompany/sample' is a fully qualified name of your parsers. That will be the way to uniquely identify, and deploy your parsers on a production punch.
* `parser.punch` and `enrich.punch` are sample punchlets. Check them out they illustrates the basics. This is where you write the actual logic of your log parsing or more generally data transformation.
* `groks/pattern.grok` is a sample grok pattern. The punch comes with many patterns directly loaded, but here is how you can add your own.
* `resources/color_code.json` is a sample resource files. In this sample it is used to add a numerical color code from a color string value ('red' or 'green').
* `test/unit_chain.json` and `test/unit_punchlet.json` are punch unit test files. That lets you define unit tests to ensure each punchlet or a sequence of punchlets behave exactly as you expect.
* `test/sample.txt` is an example a sample log file. These can be used to test
a large number of logs. 

## Understand Punch Parsers Archives

Here is the logic. First note that this layout is designed to hold one or several group of punchlets.
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

in your data pipelines. As simple as that. That basic mechanism ensure your parsers will be worldwide unique.

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
---
apiVersion: 8.0
kind: PunchletGroup
metadata:
  name: "Sample group of related punchlets"
spec:
  resources:
  - name: custom_groks
    type: grok
    url: groks/pattern.grok
    description: "custom grok pattern to be loaded automatically"
  - name: standard_groks
    type: grok
    url: /usr/share/punch/resources/patterns
    description: "standard punch grok patterns"
  - name: color_codes
    type: json
    url: resources/color_codes.json
    description: "a json resource file to be loaded as a tuple"
  punchlets:
  - punchlet: parser.punch
    labels:
       description: "a sample punchlet for you to easily start coding your own"
       performance: 3000
       category: sample
       author: "punch team"
       vendor: thales
    inputStream:
    - name: logs
      fields:
      - name: data
        type: string
  - punchlet: enrich.punch
    labels:
       description: "a sample punchlet to illustrate chaining and enrichment concepts"
       performance: 2000
       category: sample
       author: "punch team"
       vendor: thales
    inputStream:
    - name: logs
      fields:
      - name: data
        type: string
```

## Package Your Parser

Go to the 'my-punchlet-parser' folder and simply type in: 

```sh
mvn clean install
```

That will test then generate your parser package in 'target/myparsers-1.0-SNAPSHOT.zip'.
That zip file is the one you can upload or publish to the punch marketplace or to your production 
punch. 

## Using Your Parsers

Once your parser are deployed, you can simply refer to them in your punchline. 
Remember a punchline is a log processing pipeline where you chain your parser. 

Checkout the https://github.com/punchplatform/starters repository for examples. 

Here is a typical punchline: 

```yaml
apiVersion: punchline.gitlab.thalesdigital.io/v2
kind: StreamPunchline
metadata:
  name: mypunchline
spec:
  containers:
    dependencies:
      - parser:org.thales.punch:cisco:latest
    applicationContainer:
      image: ghcr.io/punchplatform/punchline-starter:latest
  dag:
  - id: input
    kind: source
    type: generator_source
    exit_conditions:
     success:
        acks_greater_or_equal_to: 1
        require_no_remaining_row_to_inject: true
        require_no_pending_row: true
     failure:
        fails_greater_or_equal_to: 1
    settings:
      expectation: none
      acked:
      messages:
        - "color=red city=Rome uri=https://punchplatform.com"
    out:
    - id: parser
      table: logs
      columns:
      - name: log
        type: string
  - id: parser
    type: punchlet_function
    kind: function
    settings:
      resources:
        - name: standard_groks
          url: /usr/share/punch/resources/patterns
          type: grok
        - name: custom_groks
          url: /mypatterns.grok
          type: grok
      punchlets:
      - /punchlet.punch
    out:
    - id: print
      table: logs
      columns:
      - name: log
        type: string
      - name: kv
        type: string
      - name: sampleuri
        type: string
  - id: print
    type: punchlet_function
    kind: function
    settings:
      punchlet_code: "{print(root);}"
```
