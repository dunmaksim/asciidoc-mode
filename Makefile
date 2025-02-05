.PHONY: load-asciidoctor-json
load-asciidoctor-json:
	wget \
		https://raw.githubusercontent.com/asciidoctor/asciidoctor-vscode/refs/heads/master/syntaxes/Asciidoctor.json \
		--output-document=Asciidoctor.json \
		--show-progress \
		--timestamping
