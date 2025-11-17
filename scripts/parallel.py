import threading
import os

class runParallel(threading.Thread):
    def __init__(self, cmds):
        super(runParallel, self).__init__()
        self.cmds = cmds

    def run(self):
        if type(self.cmds) == str:
            os.system(self.cmds)
        else:
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

def exe_parallel(cmds, threads):
    cmds_list = make_parallel(cmds, threads)
    for cmd_batch in cmds_list:
        for cmd in cmd_batch:
            t = runParallel(cmd)
            t.start()
        t.join()
