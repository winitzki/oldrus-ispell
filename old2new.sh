#!/bin/sh

# Transform dictionary from old to new orthography
# Usage: sh old2new.sh directory_name

SORT="./sortkoi8c"

newdir="$1"

rm -rf "$newdir"
mkdir -p "$newdir"

# Prepare lists of words to be added and removed. This list must be in new orthography with yo and short i.
# The first list consists of words that have '�' sound represented by '�'. The old list after conversion will have them with "�" and we need to remove them
cat << EOF1 | tee base.add | grep '�' | sed -e 's/�/�/g' > base.rem
���������������
������������������/F
����������������/AEX
����ף�����/A
�ģ���/I
ף���/I
���������/I
����������/A
�������/I
�Σ��
�Σ���/O
�Σ������
�Σ������/K
���ף�����/A
�������̣����/AS
��ӣ�������/AS
�ף��
�ף�������/F
�ף�����/AZ
�ף������/I
�ף���/O
ڣ������/BL
��ģ���/I
��ģ�����/I
���/K
����/H
���������/A
������/K
���/J
�����������/J
������������/AS
��������/A
������/A
��������/J
����/H
�������/H
������������/A
������ף��
������ף���/O
�����ף��
�����ף���/O
�������ף�����/A
����������/F
��������/AS
��������������
�����������������/AX
���ף���/I
����ף�����/A
��ģ������/AX
��ģ������/BL
����ף�����/A
���������������/A
��������������/F
������������/A
�����/A
������������/F
����ģ������/AX
������ף�����/A
�ӣ�������/AS
����ӣ�������/AS
����ӣ���������/A
����ӣ�������/LMP
��ڣ��������/A
��ڣ�������/J
��ڣ��������/A
�����ף�������/A
���ӣ�������/AS
���ӣ���������/A
���ӣ�������/BLMP
���ӣ���������/LS
���ӣ���������/A
������ף��
������ף���/O
ӣ���
ӣ���/O
�ͣ���/H
������ף��
������ף���/O
�ң��ף�������/A
�������������/HQ
��������������/K
��������������/A
�������������/A
��������
����ң��ף�������/A
������ף�������/A
���������/A
EOF1

# Second list consists of words we want in both yo and ye variants (new orthography here!)
cat << EOF2 >> base.add
��ӣ����/A
�ӣ���/L
�ӣ����/A
�ӣ������/A
��ӣ���/L
��ӣ����/A
���ӣ����/A
��ӣ������/A
��ӣ����/A
ޣ��/J
ޣ����/K
ޣ����/A
EOF2

# Third list consists of words we need to remove - list them in new orthography here, after rus_old2new.pl, but only words that rus_old2new cannot remove itself
cat << EOF3 >> base.rem
����������������
�������������������/F
�����������������/AEX
����������/I
�����������/A
��������/I
���/K
����/H
���������/A
������/K
���/J
�����������/J
������������/AS
��������/A
������/A
��������/J
����/H
�������/H
������������/A
��������/K
�����������/A
�����������/F
���������/AS
��������������
�����������������/AX
���������������/A
��������������/F
������������/A
�����
�����
������/G
������
�����
�����
�����
������
�����
�����
�������������/F
�����
������
�����
�������������/AS
��������������/A
�ң�����������/A
���������������/A
�������������/HQ
��������������/K
��������������/A
�������������/A
��������
����ң�����������/A
����/J
������/K
������/A
����������/A
EOF3

# these words get mangled by rus_new2old.pl, need to fix them. This is in old orthography.
cat << EOF4 | tee geography.add | perl ./rus_old2new.pl > geography.rem
��������
������
EOF4

# replace the beginning "��" in some words. This is in new orthography.
cat << EOF41 >> geography.add
�����/J
����/H
��������/H
����/J
�������/J
������������/J
������
�������/H
���������/A
�������/A
�����������/A
��������/A
�����������/A
����������������/A
EOF41

cat << EOF42 >> geography.rem
�����/J
����/H
��������/H
����/J
�������/J
������������/J
������
�������/H
���������/A
�������/A
�����������/A
��������/A
�����������/A
����������������/A
EOF42

# same for science.koi
cat << EOF5 | tee science.add | grep '�' | sed -e 's/�/�/g' > science.rem
������ף��
������ף���/O
EOF5


for dict in abbrev base church computer for_name geography names science rare redundant
do
	echo -n "$dict ... "
	touch $dict.add $dict.rem	# In case they don't exist
	perl ./rus_old2new.pl < $dict.koi | sh $SORT | uniq | perl ./excludelines.pl -quiet $dict.rem | cat - $dict.add | sh $SORT | uniq > "$newdir"/$dict.koi
	rm -f $dict.add $dict.rem
done
echo "done"

# special "counted.idx" dictionary
perl ./rus_old2new.pl < counted.idx > "$newdir"/counted.idx


# Make a full affix file for new orthography by 1) uncommenting lines that are NOYER-specific; 2) removing lines that are YER-specific and lines specific to old orthography; 3) removing YER from affix rules; 4) cleaning up affix rules that were corrupted after removing YER; removing empty lines; 5) convert rules and comments to new orthography, replacing certain words 

cat oldrussian.aff.koi | sed -e 's/^#noer//; s/^#nr//; s/^#r.*$//; s/^#o.*$//;' | perl -e 'while(<>){s/[��]([ \t.,\/\#])/\1/g;s/[��]$//; s/-,//;s/,\t/,-\t/; print unless(/^\s*$/);}' | sed -e 's/�/�/;y/������/������/;s/^\#o.*$$//;s/^\#r.*$//;s/���/���/;s/���/���/;s/�����/�����/;s/��� /��� /;s/���$/���$/;s/�����/�����/;s/��� /��� /;s/���$/���$/;s/��/��/;' > "$newdir"/oldrussian.aff.koi

