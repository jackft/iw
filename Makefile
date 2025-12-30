.PHONY: all run clean

all: install run

install:
	Rscript -e "if (!requireNamespace('renv', quietly = TRUE)) install.packages('renv'); renv::restore()"

run:
	Rscript analysis.R

clean:
	rm -f results/*
	rm -f figures/*
	rm -rf renv/library