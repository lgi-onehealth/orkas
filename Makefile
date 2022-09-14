.PHONY: cloud test clean

SUBWF=reference_preprocessing
WF=create_masks

cloud:
	NXF_VER=22.08.0-SNAPSHOT nextflow run main.nf -work-dir gs://fastq-minag/work -resume -profile google_life_sciences

batch:
	NXF_VER=22.08.0-SNAPSHOT nextflow run main.nf -work-dir gs://fastq-minag/work -resume -profile google_batch

local:
	nextflow -C nextflow-local.config run main.nf -resume

test: clean
	pytest -n 4 --symlink --kwdof --color=yes --git-aware

clean:
	rm -rf work test_output .nextflow*

local_sw_test:
	nextflow -C tests/config/nextflow.config run ./tests/subworkflows/$(SUBWF) -entry test_$(SUBWF) -profile $(SUBWF) -resume

test_paths:
	find test_output/${WF} -type f -name "*" | sed -E 's/(.*)/- path: .\/\1/g'