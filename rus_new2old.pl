#!/usr/bin/perl

# Insert some old Russian orthography where it is trivial to do so.
# Version of Sept. 4, 2000
# Flags: -nocaps	disable modification of capitalized letters altogether
# -allcaps	modify all caps just as lowercase and insert capital er
# both -allcaps and -nocaps result in adding uppercase Er to uppercase prepositions only but not to other uppercase words
# default is to only add lowercase Er after "V", "K", "S" and not touch any other uppercase trailing consonants assuming that they are abbreviations
# -bylines: do not swallow all input but process it line by line and print results

# Parse options
$allcaps = ("@ARGV" =~ /-allcaps/) ? 1 : 0;
$nocaps = ("@ARGV" =~ /-nocaps/) ? 1 : 0;
$Er = ($allcaps) ? "�" : "�";
$RL = ("@ARGV" =~ /-RL/i) ? 1 : 0;

$wb='[^A-z0-9�-��-߲���������]';
$letter='[�-��-߲���������]';

undef $/ unless ("@ARGV" =~ /-bylines/);

while(<STDIN>) {
# Insert hard signs and roman i's automatically.
	# Hard signs at end of words
	s/([�������������������ݬ])([^���-��-���������])/$1�$2/g;
	s/([���������������������])([^���-��-���������])/$1�$2/g if ($allcaps and not $nocaps);	# This allows modification of capitalized words (but danger to things like ���� which become �����)
	s/($wb)([���])([^���-��-���������."!?])/$1$2$Er$3/g if ($allcaps or not $nocaps);	# Prepositions may be capitalized
	s/^([���])([^���-��-���������."!?])/$1$Er$2/g if ($allcaps or not $nocaps);	# Prepositions may be capitalized but not followed by some punctuation
	# Roman i (��)
	s/�([�ţ������������������])/�$1/g;
	s/�([�ţ������������������])/�$1/g;
	# Do not replace � in composite words with ����- �����- ����- ������-  ������- ������- -�����-
	s/^([��]��)�/$1�/g;
	s/^([��]���)�/$1�/g;
	s/^([��]��)�(?=[��])/$1�/g;	# ��ͦ�����, �� ������������, �����������
	s/^([��]����)�/$1�/g;
	s/^([��]�[��]��)�/$1�/g;
	s/($wb)([��]��)�/$1$2�/g;
	s/($wb)([��]���)�/$1$2�/g;
	s/($wb)([��]��)�(?=[��])/$1$2�/g;	# ��ͦ�����, �� ������������, �����������
	s/($wb)([��]����)�/$1$2�/g;
	s/($wb)([��]�[��]��)�/$1$2�/g;
	s/(����)�/$1�/g;
	# Prefixes ���-, ���-, ��-, ���-, ���-
	s/([��]�)�(?=[��������])/\1�/g;
	s/($wb)([��]?[��]�)�(?=(�[^�]|��[$letter]|�[^��]))/\1\2�/g;	# Avoid ��������, ���Ԧ�, ����������
	s/^([��]?[��]�)�(?=(�[^�]|��[$letter]|�[^��]))/\1�/g;
	s/([^����])([��][��])�(?=[�])/\1\2�/g;     # ���-(�), ���-(�). Avoid �����, ������
	s/^([��][��])�(?=[�])/\1�/g; 
	s/([��]�)�(?=[�])/\1�/g;        # ���-(�)
	s/($wb)([��])�(?=[�])/\1\2�/g;  # ^��-(�)
	s/^([��])�(?=[�])/\1�/g;  # ^��-(�)

	# Replace some obsolete word spellings
	s/�����/������/g;	# �������
	s/���æ/����æ/g;	# ����æ������
	s/�������/�������/g;	# ���������æ�
	s/([��])(�����)(�[��]|���)/\1�\2\3/g;	# �������������

	# Replace � by � where it's unambiguous
	s/([��]�)�([�])/\1�\2/g;  # �ɬ��, �����ɬ�

	# Replace � by � where it's unambiguous
	s/([����]�)�([���])/\1�\2/g;  # �ע�, �ע�, �ע�, �ע�, �ע�
	s/([^�������])�(��)/\1�\2/g;  # most verbs on -���
	s/([^�]�)�(��)/\1�\2/g;  # most verbs on -͢�� (except ���������)
	s/([^��]�|${letter}��)�(��$|��[^�])/\1�\2/g;  # most verbs on -Ң�� (except ������, ������, ������) avoid �����������
	s/([^��]�|${letter}��)�(��)/\1�\2/g;  # most verbs on -̢�� (avoid �����)
	s/([^���])�([��]�)/\1�\2/g;  # -��ۦ�
	s/([^����]|[^��]�|$letter[^�]�)�(��)/\1�\2/g;  # -��ݦ�, �� ���ݦ�, ����ݦ�, ����ݦ�...
	s/^�(��)/�\1/g;  # ����
	s/([��������]�)�(��|[ţ��])/\1�\2/g;  # �͢�, �͢�, �͢�, �͢��, ...
	s/([��]�)�(�)/\1�\2/g;  # �͢�
	s/([��]��|��)�(�)/\1�\2/g;  # ��ע��, ��ע��, ...
	s/([��]��)�(�[�ţ����])/\1�\2/g;  # ��Ң�- ...
	s/([^��]|$wb)��(�[��])/\1¢\2/g;  # ��¢����, ...
	s/^(�)�(�[��])/\1�\2/g;  # ¢����, ...
	s/(�|��|�)��(�)/\1΢\2/g;  # �΢����
	s/([��]�)�(�[^�])/\1�\2/g;  # �Ң��, �� �� "��������������"
	s/(��)�(�[������]|���|�[^�])/\1�\2/g;  # â���, ...
	s/([����]�)�(�)/\1�\2/g;  # ��Ӣ��, ...
	s/([���]�)�([��])(?=[^�])/\1�\2/g;  # ���Ģ���
	s/([��]����)�([��])/\1�\2/g;  # ����ע��, ...
	s/([��]�|[��]�)[ţ](��)/\1�\2/g;  # �ע���, �΢���, ...
	s/([��])�(�[����])/\1�\2/g;  # â��, â�����, ��â����, ...
	s/([��])�(��)/\1�\2/g;	# Ģ�����
	s/(([^�]|$wb)[��])�(����)/\1�\3/g;	# Ģ���������, �� ���������, ���������
	s/^([��])�(����)/\1�\2/g;	# Ģ���������, �� ���������, ���������
	s/(�)�(�[��])/\1�\2/g;	# ���Ϣ��
	s/([��])�(�[��])/\1�\2/g;	# â����
	s/([��]�)�([��])/\1�\2/g;	# �Ң�-, �Ң�-
	s/([��])�(�[^���])/\1�\2/g;	# ע� - ���͢ ����, ����, ����
	s/([��])�(�[ţ�])/\1�\2/g;	# -â�-

	# Russkaja Latinica stuff: Replace f~ by fita, ~v by izhitsa, i~ by i roman, and e~ by yat'.
	if ($RL) {
		s/�~/�/g;
		s/�~/�/g;
		s/~V/�/g;
		s/~v/�/g;
		s/�~/�/g;
		s/�~/�/g;
		s/�~/�/g;
		s/�~/�/g;
	}
	print;
}
