#!/usr/bin/env nextflow

include { TYPING } from '../../../subworkflows/typing/main.nf';
workflow test_typing {

    input = [
                [ 
                    [ id:'LIS001', single_end:false, organism:'Listeria monocytogenes' ], // meta map
                    file(params.test_data['assemblies']['listeria'], checkIfExists: true) 
                ],
                [ 
                    [ id:'SEN001', single_end:false, organism:'Salmonella enterica' ], // meta map
                    file(params.test_data['assemblies']['salmonella'], checkIfExists: true) 
                ],
                [ 
                    [ id:'NME001', single_end:false, organism:'Neisseria meningitidis' ], // meta map
                    file(params.test_data['assemblies']['nmeningitidis'], checkIfExists: true) 
                ],
                [ 
                    [ id:'NGO001', single_end:false, organism:'Neisseria gonorrhoeae' ], // meta map
                    file(params.test_data['assemblies']['ngono'], checkIfExists: true) 
                ],
                [ 
                    [ id:'SPY001', single_end:false, organism:'Streptococcus pyogenes' ], // meta map
                    file(params.test_data['assemblies']['spyogenes'], checkIfExists: true) 
                ],

            ];
    
    ch_typing = Channel.from(input);

    TYPING(ch_typing)
}
