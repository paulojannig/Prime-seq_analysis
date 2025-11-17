import os
import argparse
import threading

## Parameters
parser = argparse.ArgumentParser()

parser.add_argument('-n','--threads', action='store', dest='threads', type=int, help='threads')
parser.add_argument('-i', action='store', dest='input_path', help='fastq path')
parser.add_argument('-t','--target', action='store', dest='target_path', help='target path')

paras = parser.parse_args()


class runParallel(threading.Thread):
    def __init__(self, cmds):
        super(runParallel, self).__init__()
        self.cmds = cmds

    def run(self):
        for cmd in self.cmds:
            os.system(cmd)


def make_parallel(cmds, threads):
    '''
    Divide tasks into blocks for parallel running.
    Put the cmd in parallel into the same bundle.
    The bundle size equals the threads.
    '''
    threads = int(threads)
    cmd_list = []
    i,j = 0,0
    for cmd in cmds:
        if j == 0:
            cmd_list.append(list())
            i += 1
        cmd_list[i-1].append(cmd)
        j = (j+1) % threads
    return cmd_list

def exe_parallel(cmd, threads):
    cmds_list = make_parallel(cmd, threads)
    for cmd_batch in cmds_list:
        for cmd in cmd_batch:
            t = runParallel(cmd)
            t.start()
        t.join()

def trim(fq1, fq2, target_path):
    # flexbar 3.5.0
    name = fq1.split('/')[-1].strip('_1.fq.gz')
    cmd = [f'cutadapt -j 4 -a  T{{17}}N{{83}} -A A{{17}}N{{83}} -o {target_path}{name}_cutadapt_1.fastq.gz -p {target_path}{name}_cutadapt_2.fastq.gz {fq1} {fq2} --pair-filter=any -m 28:50; fastp --in1 {target_path}{name}_cutadapt_1.fastq.gz --in2 {target_path}{name}_cutadapt_2.fastq.gz --out1 {target_path}{name}_cutadapt_trimG_1.fastq.gz --out2 {target_path}{name}_cutadapt_trimG_2.fastq.gz -l 28 -h {target_path}{name}_fastp.html &> {target_path}{name}_fastp.log']
    #cmd = [f'flexbar -n 4 -r {fq2} -x 16 --htrim-right AT --htrim-min-length 10 --htrim-error-rate 0.1 -z GZ --output-reads {target_path}{name}']
    ## flexbar is not very good at polyA and primer detection
    # cmd = [f'cutadapt -j 4 -a A{{17}}N{{83}} -u 15 -m 50 -o {target_path}{name}_cutadapt_2.fq.gz {fq2} 2> {target_path}{name}_cutadapt.log']
    return(cmd)

def load_fq(path):
    fq1 = sorted([f for f in os.listdir(path) if f.endswith(("_1.fastq.gz", "_1.fq.gz"))])
    fq2 = sorted([f for f in os.listdir(path) if f.endswith(("_2.fastq.gz", "_2.fq.gz"))])
    return zip(fq1, fq2)


if __name__ == '__main__':
    fqs = load_fq(paras.input_path)
    cmds = []
    for fq1, fq2 in fqs:
        #sample_id = '_'.join(fq1.split('_')[:2])
        #sample_id = os.path.basename(paras.input_path) # By PJ
        print(fq1, fq2)
        _fq1 = os.path.join(paras.input_path, fq1)
        _fq2 = os.path.join(paras.input_path, fq2)
        #_target_path = os.path.join(paras.target_path, sample_id) + "/" 
        _target_path = os.path.join(paras.target_path) + "/"  # By PJ
        os.path.exists(_target_path) or os.makedirs(_target_path)
        cmds.append(trim(_fq1, _fq2, _target_path))
    exe_parallel(cmds, paras.threads)
