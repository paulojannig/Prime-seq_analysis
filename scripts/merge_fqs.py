#!/home/hong/anaconda3/bin/python
import os
from os import walk
#from utils import parallel
## for local usage, instead of install as a site-package
import parallel
import argparse

parser = argparse.ArgumentParser()

parser.add_argument('-n','--threads', action='store', dest='threads', type=int, help='threads')
parser.add_argument('-i','--input_folder', action='store', dest='input_folder', help='input fastq folder')
parser.add_argument('-o','--output_folder', action='store', dest='output_folder', help='output fastq folder')

paras = parser.parse_args()

class replicate:
    r1s = []
    r2s = []
    names = {}
    def __init__(self, name, r1_suffix, r2_suffix):
        self.name = name
        self.r1_suffix = r1_suffix
        self.r2_suffix = r2_suffix
        self.r1_names = []
        self.r2_names = []
    def get_r1s(self):
        for (dirpath, dirnames, filenames) in walk(f'{paras.input_folder}{self.name}'):
            for filename in filenames:
                if filename.endswith(self.r1_suffix):
                    self.r1_names.append(filename.removesuffix(self.r1_suffix))
        self.r1_names.sort()
    def get_r2s(self):
        for (dirpath, dirnames, filenames) in walk(f'{paras.input_folder}{self.name}'):
            for filename in filenames:
                if filename.endswith(self.r2_suffix):
                    self.r2_names.append(filename.removesuffix(self.r2_suffix))
        self.r2_names.sort()
    def get_names(self):
        assert self.r1_names == self.r2_names, "paired reads do not match"
        self.names = set(self.r1_names)
        assert len(self.names) > 0, "No sequence file found"
    def concate_fqs(self):
        self.r1s = [paras.input_folder+self.name+'/'+r+self.r1_suffix for r in self.names]
        self.r2s = [paras.input_folder+self.name+'/'+r+self.r2_suffix for r in self.names]
        if len(self.r1s) > 1:
            r1_zcat_list = ' '.join(self.r1s)
            if '.gz' not in r1_zcat_list:
                cmd1 = f'mkdir -p cat {paras.output_folder}{self.name}; {r1_zcat_list} | pigz > {paras.output_folder}{self.name}/{self.name}_merge_1.fq.gz'
            else:
                cmd1 = f'mkdir -p cat {paras.output_folder}{self.name}; cat {r1_zcat_list} > {paras.output_folder}{self.name}/{self.name}_merge_1.fq.gz'
            #os.system(cmd1)
            r2_zcat_list = ' '.join(self.r2s)
            if '.gz' not in r2_zcat_list:
                cmd2 = f'mkdir -p cat {paras.output_folder}{self.name}; cat {r2_zcat_list} | pigz > {paras.output_folder}{self.name}/{self.name}_merge_2.fq.gz'
            else:
                cmd2 = f'mkdir -p cat {paras.output_folder}{self.name}; cat {r2_zcat_list} > {paras.output_folder}{self.name}/{self.name}_merge_2.fq.gz'
            #os.system(cmd2)
        else:
            if '.gz' not in self.r1s[0]:
                cmd1 = f'mkdir -p cat {paras.output_folder}{self.name}; pigz {self.r1s[0]} > {paras.output_folder}{self.name}/{self.name}_merge_1.fq.gz'
            else:
                cmd1 = f'mkdir -p cat {paras.output_folder}{self.name}; mv {self.r1s[0]} {paras.output_folder}{self.name}/{self.name}_merge_1.fq.gz'
            #os.system(cmd1)
            if '.gz' not in self.r2s[0]:
                cmd2 = f'mkdir -p cat {paras.output_folder}{self.name}; pigz {self.r2s[0]} > {paras.output_folder}{self.name}/{self.name}_merge_2.fq.gz'
            else:
                cmd2 = f'mkdir -p cat {paras.output_folder}{self.name}; mv {self.r2s[0]} {paras.output_folder}{self.name}/{self.name}_merge_2.fq.gz'
            #os.system(cmd2)
        return [cmd1, cmd2]

if __name__ == '__main__':
    cmds = []
    for (dirpath, dirnames, filenames) in walk(paras.input_folder):
        for dirname in dirnames:
            pgc_rep = replicate(dirname, '_1.fq.gz', '_2.fq.gz')
            pgc_rep.get_r1s()
            pgc_rep.get_r2s()
            pgc_rep.get_names()
            cmds += pgc_rep.concate_fqs()
    parallel.exe_parallel(cmds,paras.threads)

