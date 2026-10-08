import json,glob,sys
sys.path.insert(0,'tool')
from unwind_levelgen import valid,solve
bad=0;ids=[];stats=[]
for f in sorted(glob.glob('levels/chapter_*.json')):
    for lv in json.load(open(f))['levels']:
        th=[[tuple(n) for n in t] for t in lv['threads']]
        ok=valid(th,lv['rows'],lv['cols']); ids.append(lv['id'])
        if not ok: bad+=1; print('INVALID',lv['id'])
        depth,free0=solve(th,lv['rows'],lv['cols'])
        nodes=sum(len(t) for t in th)
        stats.append((lv['id'],lv['cols'],lv['rows'],len(th),nodes,depth,free0,lv['shape']))
assert ids==list(range(1,201)),'ids not contiguous'
print('levels',len(ids),'invalid',bad)
import statistics as s
print('threads min/median/max',min(x[3] for x in stats),s.median(x[3] for x in stats),max(x[3] for x in stats))
print('level1',stats[0]); print('level5',stats[4]); print('level20',stats[19]); print('level100',stats[99]); print('level200',stats[199])
print('min free at start',min(x[6] for x in stats),'min depth',min(x[5] for x in stats))
print('shapes',sorted({x[7] for x in stats}))
print('max cols',max(x[1] for x in stats),'max rows',max(x[2] for x in stats))
