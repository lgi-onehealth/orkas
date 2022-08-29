.PHONY: cloud test clean


cloud:
	NXF_VER=22.08.0-SNAPSHOT nextflow run main.nf -work-dir gs://fastq-minag/work -resume -profile google_life_sciences

batch:
	NXF_VER=22.08.0-SNAPSHOT nextflow run main.nf -work-dir gs://fastq-minag/work -resume -profile google_batch

local:
	nextflow -C nextflow-local.config run main.nf -resume

test: clean
	pytest --symlink --kwdof --color=yes --git-aware

clean:
	rm -rf work test_output
