task ReadGroup {
    String SM
    String RG
    String LB
    String PU
    String PL
    String PM

    String docker
    Int disk_space

	Int preemptible_count
    String RGline="ID:${RG} SM:${SM} LB:${LB} PL:${PL} PU:${PU} PM:${PM}"  
	
    command <<<
     echo ${RGline}
    >>>
    
	output {
		String Read_group_line = read_string(stdout())
	}

	runtime {
		docker: docker
		memory: "1 GB"
		disks: "local-disk ${disk_space} HDD"
		preemptible: preemptible_count
	}
}
