rule get_csstar_script:
    output:
        csstar = os.path.join(config['params']['binary_dir'], "c-SSTAR", "c-SSTAR")
    params:
        bin_dir = config['params']['binary_dir']
    shell:
        """
        mkdir {params.bin_dir}
        cd {params.bin_dir}
        git clone https://github.com/chrisgulvik/c-SSTAR
        """

rule get_csstar_database:
    output:
        dbfile = os.path.join(config['params']['db_dir'], "ResGANNOT_srst2.fasta"),
        dbversion = os.path.join(config["params"]["db_dir"], "ResGANNOT_srst2_version.txt")
    params:
        db_source = config["params"]["csstar"]["db_source"],
        dateformat = config["params"]["dateformat"]
    shell:
        """
        wget -O {output.dbfile} {params.db_source}
        date +"{params.dateformat}" > {output.dbversion}
        """

rule run_csstar:
    input:
        contigs = get_assembly,
        csstar = os.path.join(config['params']['binary_dir'], "c-SSTAR", "c-SSTAR"),
        resgannot_db = os.path.join(config['params']['db_dir'], "ResGANNOT_srst2.fasta"),
        dbversion = os.path.join(config["params"]["db_dir"], "ResGANNOT_srst2_version.txt")
    output:
        report = "results/{sample}/csstar/report.tsv",
        metadata = "results/{sample}/csstar/metadata.txt"
    message: "Running rule run_csstar on {wildcards.sample} with contigs"
    log:
       "logs/csstar_{sample}.log"
    conda:
      "../envs/csstar.yaml"
    threads:
       config["params"]["threads"]
    params:
        outdir = 'results/{sample}/csstar',
        logfile = "results/{sample}/csstar/c-SSTAR_*.log"
    shell:
       """
       {input.csstar} -g {input.contigs} -d {input.resgannot_db} --outdir {params.outdir} > {output.report} 2>{log}
       grep "c-SSTAR version" {params.logfile} | perl -p -e 's/.+c-SSTAR version: (.+)/--analysis_software_version $1/' > {output.metadata}
       cat {input.dbversion} | perl -p -e 's/(.+)/--reference_database_version $1/' >> {output.metadata}
       """

rule hamronize_csstar:
    input:
        contigs = get_assembly,
        report = "results/{sample}/csstar/report.tsv",
        metadata = "results/{sample}/csstar/metadata.txt"
    output:
        "results/{sample}/csstar/hamronized_report.tsv"
    conda:
        "../envs/hamronization.yaml"
    shell:
        """
        hamronize csstar --input_file_name {input.contigs} --reference_database_name ResGANNOT $(paste - - < {input.metadata}) {input.report} > {output}
        """

