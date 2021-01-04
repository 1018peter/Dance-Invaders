#!/bin/bash

echo touch alien_rom.mem
for _size in $(seq 0 15); do 
	for _type in $(seq 0 1); do 
		for _frame in $(seq 0 1); do 
			for _deriv in $(seq 0 3); do 
				if [ "${_size}" != "0" ] || [ "${_type}" != "0" ] || [ "${_frame}" != "0" ] || [ "${_deriv}" != "0" ] ; then 
					echo -n " " >> alien_rom.mem;
				fi
				cat "size${_size}_type${_type}_frame${_frame}_deriv${_deriv}.mem" >> alien_rom.mem
			done
		done
	done
done

