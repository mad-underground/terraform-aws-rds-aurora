import re

variable_regex = re.compile('var.([a-zA-Z_0-9]*)[\W|\s]*')

files_to_process = [
    {
        'source_file': 'main.tf.orig',
        'destination_file': 'main.tf',
        'variable_name': 'aurora_db'
    },
    {
        'source_file': 'outputs.tf.orig',
        'destination_file': 'outputs.tf',
        'variable_name': 'aurora_db'
    }
]

for file in files_to_process:
    with open(file['destination_file'], 'w') as write_f:
        with open(file['source_file'], encoding="utf-8") as read_f:
            for line in read_f:
                new_line = line
                variable_matches = variable_regex.findall(line.strip())
                if variable_matches is not None and len(variable_matches) > 0:
                    for v in variable_matches:
                        new_line = new_line.replace(f'var.{v}', f'var.{file["variable_name"]}.{v}')
                write_f.write(f'{new_line}')
