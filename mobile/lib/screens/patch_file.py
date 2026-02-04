
import os

target_file = r"d:\study\MEETING_APP\mobile\lib\screens\meeting_detail_screen.dart"
new_func_file = r"d:\study\MEETING_APP\mobile\lib\screens\temp_new_func.txt"

def patch_file():
    try:
        with open(target_file, 'r', encoding='utf-8') as f:
            lines = f.readlines()
        
        with open(new_func_file, 'r', encoding='utf-8') as f:
            new_func_content = f.read()

        start_index = -1
        end_index = -1

        for i, line in enumerate(lines):
            if "void _showConvertToTaskDialog(" in line:
                start_index = i
            if "Widget _buildTasksCard(" in line:
                end_index = i
                break # Found the start of the NEXT function
        
        if start_index != -1 and end_index != -1:
            print(f"Found function start at line {start_index} and end at line {end_index}")
            
            # Keep lines before start_index
            # Insert new content
            # Keep lines from end_index onwards
            
            new_content = "".join(lines[:start_index]) + new_func_content + "\n\n  " + "".join(lines[end_index:])
            
            with open(target_file, 'w', encoding='utf-8') as f:
                f.write(new_content)
                
            print("Successfully patched the file.")
        else:
            print("Could not find start or end markers.")
            print(f"Start index: {start_index}")
            print(f"End index: {end_index}")

    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    patch_file()
