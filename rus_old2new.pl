#!/usr/bin/perl

# Convert old Russian orthography to new
# After running this script, check "-��" -> "��", "���", "���"

undef $/ unless ("@ARGV" =~ /-bylines/);

$wb='[^A-z0-9�-��-߲���������]';
$letter='[�-��-߲���������]';

while(<STDIN>) {
	# Replace some prefixes.
	s/([��]�)�(?=[����������])/\1�/g;	# ���-(...)
	s/([��][��])�(?=[�])/\1�/g;	# ���-(�), ���-(�)
	s/([��]�)�(?=[�])/\1�/g;	# ���-(�)
	s/($wb)([��])�(?=[�])/\1\2�/g;	# ^��-(�)
	# Replace obsolete words: ��, ���, �΢, ��΢
	s/($wb)([��])�(?=$wb)/\1\2�/g;
	s/($wb)���(?=$wb)/\1�ţ/g;
	s/($wb)([��]�?)΢(?=$wb)/\1\2��/g;
	# Replace obsolete word endings: -��, -���, -���
	s/��(?=$wb)/��/g;
	s/(��|��|[���]��|�|�|��)��(?=$wb)/\1��/g;	# Careful with replacing -��! Lots of words end with a legitimate -��.
	s/([����])���(?=$wb)/\1���/g;	# Careful
	s/([^�][�]|$letter[�]|[^�][�]|$letter�[�]|[�������������])���(?=$wb)/\1���/g;	# Careful: �����, ����, �������. ��: �������, ¢������.
	s/���(?=$wb)/���/g;
	# Replace some obsolete word spellings
	s/������/�����/g;	# �������
	s/�����/����/g;	# ����æ������
	s/�������/�������/g;	# ���������æ�
	s/([��])�(�����)(�[��]|���)/\1\2\3/g;	# �������������

	# Now can replace Yat' by E, I roman by I, Fita by F
	tr/��������/��������/;
	# Remove trailing er
	s/([�������������������ݬ���������������������])[��](?=$wb)/\1/g;
	s/([�������������������ݬ���������������������])[��]([- .,?!\/\\\"\':;+*^\t\n])/\1\2/g;
	s/([�������������������ݬ���������������������])[��]$/\1/g;

	# Remove er before non-ioted vowels
	s/�(?=[�����])//g;
	s/�([�])/�/g;

	print;
}
