import re,os, shutil, string
l2=[]
# 这里如果是windows系统，请按windows的目录形式写，如c:\\text
def change(dir,name):
    for i in os.listdir(dir):
        if i == name:
            newfile = i.replace('shader', 'txt')
            # 用_替代.，规则可以自己写。

            oldname = dir + '/' + str(i)
            newname = dir + '/' + str(newfile)
            shutil.move(oldname, newname)

def change1(dir,name):
    for i in os.listdir(dir):
        if i == name:
            newfile = i.replace('txt', 'shader')
            # 用_替代.，规则可以自己写。

            oldname = dir + '/' + str(i)
            newname = dir + '/' + str(newfile)
            shutil.move(oldname, newname)

def check_types(cot):
    types=''
    l_check = ['2D','range','COLOR']
    l_check_return = ['sampler2D','float','float3']
    types_pos = cot.find('(')
    types_pos1 = cot.find(')')
    c1 = cot[types_pos:types_pos1+1]
    #print(c1)
    a=0
    for i in l_check:
        if re.search(i,c1):
            if types_pos == -1 or types_pos1 == -1:
                continue
            else:
                types = l_check_return[a]
                # print(types)
        a+=1
    return types

def file_find(file):

    f_text = open(file, "r", encoding='utf-8')
    f_tee = f_text.read()
    f_tee_s = 'SubShader'
    sea_pos = f_tee.find(f_tee_s)
    count=0
    cot_range=f_tee[:sea_pos]
    cot_count=cot_range.count('\n')
    f_text.close()
    print(cot_count)

    l1 = {}
    s = ' '
    f_text = open(file, "r", encoding='utf-8')

    for j in f_text.readlines():
        # print(j)
        count+=1
        cot = j
        pos = cot.find('_')
        pos1 = cot.find('(')
        types = check_types(cot)
        if pos == -1 or pos1 == -1 or pos > pos1:
            continue
        else:
            s1 = cot[pos:pos1]
            l1[s1] = types
    for i in l1:

        a='\t'*3+'uniform'+s+l1[i]+s+i+';'
        l2.append(a)
        #print(a)

def article_check(f_add):
    print("\n****上面是没处理过的文本*****")
    print("\n****下面是处理过的文本*****")
    cot_add='\n'.join(l2)
    # print(cot_add)
    f_text = open(f_add, "r+",encoding='utf-8')
    cot1 = f_text.read()
    cot = cot1
    cot_search = 'target 3.0'
    main_pos = cot.find(cot_search)
    main_pos1 = cot.find('struct')

    if main_pos != -1 or main_pos1 != -1:
        cot_addd =cot[:main_pos+len(cot_search)]+'\n'*2 + cot_add +'\n'*2+'\t'*3+ cot[main_pos1:]
        f_text.close()
        f_text = open(f_add,"w+",encoding='utf-8')
        f_text.write(str(cot_addd))
        f_text.close()

dir = r"E:\UNITY\New Unity Project\Assets\New11"
name = "NewUnlitShader.shader"
name1 = "NewUnlitShader.txt"

change(dir,name)

file_find("E:\\UNITY\\New Unity Project\\Assets\\New11\\"+name1)
article_check("E:\\UNITY\\New Unity Project\\Assets\\New11\\"+name1)

change1(dir,name1)

