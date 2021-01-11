import time

def file_find(file):

    f_text = open(file, "r", encoding='utf-8')
    f_tee = f_text.read()
    sea_pos = f_tee.find(',')
    count=0
    cot_range=f_tee[:sea_pos]
    cot_count=cot_range.count('\n')
    f_text.close()

    l1 = {}
    s = ' '
    f_text = open(file, "r", encoding='utf-8')

    for j in f_text.readlines():
        # print(j)
        count+=1
        cot = j
        pos = cot.find('_')
        pos1 = cot.find('(')
        print(j)
        time.sleep(0.3)

file_find(r"C:\Users\1\Desktop\ArtSchool.shader")

