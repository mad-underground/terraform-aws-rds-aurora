import re

variable_regex = re.compile('^variable[\s]*"(.*)"[\s]*\{$')
description_regex = re.compile('^description[\s]*=[\s]*(".*")$')
type_regex = re.compile('^type[\s]*=[\s]*(.*)$')
default_regex = re.compile('^default[\s]*=[\s]*(.*)$')
validation_regex = re.compile('^validation[\s]*\{[\s]*$')
end_regex = re.compile('^.*\}$')

files_to_process = [
    {
        'source_file': 'variables.tf.orig',
        'destination_file': 'variables.tf',
        'variable_name': 'aurora_db',
        'description': 'AWS Aurora Database to be created'
    }
]

for file in files_to_process:
    with open(file['destination_file'], 'w') as write_f:
        write_f.write(f'variable "{file["variable_name"]}" {{\n')
        write_f.write(f'  description = "{file["description"]}"\n')
        write_f.write('  type = object({\n')

        with open(file['source_file'], encoding="utf-8") as read_f:
            new_line = {
                "variable_name": None,
                "description": None,
                "type": None,
                "default": None
            }
            isMultiLineDefault = False
            isOpenSquareBracket = False
            isOpenCurlyBracket = False
            isValidationBlock = False
            for line in read_f:
                variable_match = variable_regex.match(line.strip())
                description_match = description_regex.match(line.strip())
                type_match = type_regex.match(line.strip())
                default_match = default_regex.match(line.strip())
                validation_match = validation_regex.match(line.strip())
                end_match = end_regex.match(line.strip())

                if variable_match:
                    new_line['variable_name'] = variable_match.group(1).strip()
                elif description_match:
                    new_line['description'] = description_match.group(1).strip()
                elif type_match:
                    new_line['type'] = type_match.group(1).strip()
                elif default_match:
                    new_line['default'] = default_match.group(1).strip()
                    if new_line['default'] == '[':
                        new_line['default'] += '\n'
                        isMultiLineDefault = True
                        isOpenSquareBracket = True
                    elif new_line['default'] == '{':
                        new_line['default'] += '\n'
                        isMultiLineDefault = True
                        isOpenCurlyBracket = True
                elif isMultiLineDefault:
                    new_line['default'] += f'  {line}'
                    if line.strip() == ']' and isOpenSquareBracket:
                        isMultiLineDefault = False
                        isOpenSquareBracket = False
                    elif line.strip() == '}' and isOpenCurlyBracket:
                        isMultiLineDefault = False
                        isOpenSquareBracket = False
                elif validation_match:
                    isValidationBlock = True
                elif isValidationBlock:
                    if line.strip() == '}':
                        isValidationBlock = False
                elif end_match:
                    write_f.write(f'    # {new_line["description"]}\n')
                    write_f.write(f'    {new_line["variable_name"]} = optional({new_line["type"]}, {new_line["default"].rstrip()})\n')
                    write_f.write('\n')

        write_f.write('  })\n')
        write_f.write('}\n')
