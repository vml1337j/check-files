#!/bin/bash

declare -A interfaces=(["RU_TEST"]="10:00" ["RU_QWERTY"]="9:00" ["RU_ZZZ"]="6:00")
#declare -A interfaces=(["RU_TEST"]="10:00")

path="/home/vml1337j/script"

#today_date=$(date  '+%Y%m%d')
today_date=$(date '+%Y%m%d')
#yesterday_date=$(date  '+%Y%m%d' -d 'yesterday')
yesterday_date=$(date -v -1d '+%Y%m%d')
#current_time=$(date '+%H:%M')
current_time=$(date -v +10M '+%H:%M') # текущее время + немного на загрузку ?

# Будем бежать по ключам мапы (названия интерфейсов "RU_TEST")
# Будем получать значение (время забора файлов в collector interface + несколько минут)
# Будем сравнивать полученное время с тем временем которое сейчас и если тру
# То будет производиться сравнение файлов, иначе дописываем в файл что ничего не было загружено вообще или пока (хз)

# Файл в который выписывается информация по загруженным интерфейсам
output_file=interfaces.txt
if [ -f "$output_file" ]; then
	rm $output_file
    	touch $output_file
else
	touch $output_file
fi

for interface in ${!interfaces[@]}
do
	if [ $(date -d"${interfaces[$interface]}" +%s) -lt $(date -d"$current_time" +%s) ]; then

		# Когда каталог есть, чтобы не сорить ошибками
		if [ -d "$path/$interface/$today_date" ]; then
			today_files=$(ls $path/$interface/$today_date | wc -l)
			today_bytes=$(du $path/$interface/$today_date | awk '{print $1}')

			yesterday_files=$(ls $path/$interface/$yesterday_date | wc -l)
			yesterday_bytes=$(du $path/$interface/$yesterday_date | awk '{print $1}')

			if [ $yesterday_files -ne 0 ] && [ $yesterday_bytes -ne 0 ]; then

				# Различие в кол-ве файлов
				let diff_files=$(( ($today_files - $yesterday_files) * 100 / $yesterday_files ))
				if [ $diff_files -lt -10 ] || [ $diff_files -gt 10 ]; then

					# вывод в файл тех интерфейсов в который есть различия на 10%
					echo Number of files: $interface/$today_date $diff_files% >> $output_file
				fi

				# Различие в байтах
				let diff_bytes=$(( ($today_bytes - $yesterday_bytes) * 100 / $yesterday_bytes ))
				if [ $diff_bytes -lt -10 ] || [ $diff_bytes -gt 10 ]; then

					# вывод в файл тех интерфейсов в который есть различия на 10%
					echo Folder size: $interface/$today_date $diff_bytes% >> $output_file
				fi
			else

				# Выводим в файл что ничего не было загружено
				echo $interface: $yesterday_date no files uploaded or size of folder is 0 >> $output_file
			fi
		fi
	fi
done

# Потом грепнуть кол-во строк
