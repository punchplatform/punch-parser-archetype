all: image
FORCE: ;

image: FORCE
	docker run \
		-v ${PWD}/punchline.yaml:/punchline.yaml \
		-v ${PWD}/log4j2-stdout.xml:/opt/punch/log4j2/log4j2-stdout.xml \
 		-v ${PWD}/log4j2.properties:/opt/punch/log4j2/log4j2.properties \
		-v ${PWD}/../target/${artifactId}-${version}.zip:/usr/share/punch/artifacts/${packageInPathFormat}/${artifactId}/${version}/${artifactId}-${version}.zip \
		ghcr.io/punchplatform/punchline-java:8.0-dev \
		/punchline.yaml

