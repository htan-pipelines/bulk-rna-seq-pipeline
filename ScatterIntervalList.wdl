
task ScatterIntervalList {

	File interval_list
	Int scatter_count
	String gatk_path
	String docker
	Int preemptible_count

    command <<<
        set -e
        mkdir out
        ${gatk_path} --java-options "-Xms1g" \
            IntervalListTools \
            --SCATTER_COUNT ${scatter_count} \
            --SUBDIVISION_MODE BALANCING_WITHOUT_INTERVAL_SUBDIVISION_WITH_OVERFLOW \
            --UNIQUE true \
            --SORT true \
            --INPUT ${interval_list} \
            --OUTPUT out
	
        python3 <<CODE
        import glob, os
        # Works around a JES limitation where multiples files with the same name overwrite each other when globbed
        intervals = sorted(glob.glob("out/*/*.interval_list"))
        for i, interval in enumerate(intervals):
          (directory, filename) = os.path.split(interval)
          newName = os.path.join(directory, str(i + 1) + filename)
          os.rename(interval, newName)
        print(len(intervals))
        f = open("interval_count.txt", "w+")
        f.write(str(len(intervals)))
        f.close()
        CODE
    >>>

    output {
        Array[File] out = glob("out/*/*.interval_list")
        Int interval_count = read_int("interval_count.txt")
    }

    runtime {
        disks: "local-disk 1 HDD"
        memory: "2 GB"
        docker: docker
        preemptible: preemptible_count
    }
}

workflow ScatterIntervalList_workflow{
    call ScatterIntervalList
}
