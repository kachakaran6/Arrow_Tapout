#!/usr/bin/env python3
"""Reference level generator for Unwind (lattice-node model).
Nodes are lattice points (r,c). A thread is a self-avoiding orthogonal path of nodes, tail->head.
Head direction = last step. Ray = nodes from head forward to lattice edge.
A level is solvable iff greedy removal clears the board (removal never blocks anything).
Reverse construction: a new thread's ray may not touch any already-placed thread (those are removed later).
"""
import json, math, random, sys, hashlib
from collections import defaultdict

D = {'U':(-1,0),'R':(0,1),'D':(1,0),'L':(0,-1)}
def head_dir(cells):
    (r0,c0),(r1,c1)=cells[-2],cells[-1]
    return (r1-r0,c1-c0)
def ray(cells,rows,cols):
    dr,dc=head_dir(cells); r,c=cells[-1]; out=[]
    r+=dr;c+=dc
    while 0<=r<rows and 0<=c<cols:
        out.append((r,c)); r+=dr;c+=dc
    return out

def solve(threads,rows,cols):
    occ={}
    for i,t in enumerate(threads):
        for n in t: occ[n]=i
    active=set(range(len(threads))); rounds=0; first_free=None
    rays=[ray(t,rows,cols) for t in threads]
    while active:
        free=[i for i in active if all(n not in occ for n in rays[i])]
        if first_free is None: first_free=len(free)
        if not free: return None
        for i in free:
            for n in threads[i]: occ.pop(n,None)
            active.discard(i)
        rounds+=1
    return rounds,first_free

def valid(threads,rows,cols):
    seen=set()
    for t in threads:
        if len(t)<2: return False
        for a,b in zip(t,t[1:]):
            if abs(a[0]-b[0])+abs(a[1]-b[1])!=1: return False
        for n in t:
            if n in seen: return False
            seen.add(n)
        own=set(t)
        if any(n in own for n in ray(t,rows,cols)): return False
    return solve(threads,rows,cols) is not None

# ---------- shapes (normalised coords x,y in [-1,1], y down) ----------
def _poly(pts):
    def f(x,y):
        ins=False; n=len(pts); j=n-1
        for i in range(n):
            xi,yi=pts[i]; xj,yj=pts[j]
            if ((yi>y)!=(yj>y)) and (x<(xj-xi)*(y-yi)/(yj-yi+1e-12)+xi): ins=not ins
            j=i
        return ins
    return f
def star(x,y):
    pts=[]
    for k in range(10):
        a=-math.pi/2+k*math.pi/5; rad=1.0 if k%2==0 else 0.42
        pts.append((rad*math.cos(a),rad*math.sin(a)))
    return _poly(pts)(x,y)
def heart(x,y):
    X=x*1.25; Y=-y*1.25+0.15
    return (X*X+Y*Y-1)**3-X*X*Y**3<=0
def moon(x,y):
    return x*x+y*y<=1 and (x-0.45)**2+(y+0.05)**2>0.62**2*1.0
def diamond(x,y): return abs(x)+abs(y)<=1
def hexagon(x,y): return abs(y)<=0.88 and abs(x)*0.5+abs(y)*0.866<=0.88*0.866+0.0 and abs(x)<=1
def drop(x,y):
    if y>=-0.1: return x*x+(y-0.28)**2<=0.62**2
    return abs(x)<=0.62*(1+y)/0.9*0.9 and y>=-0.95
def bolt(x,y): return _poly([(0.25,-1),(-0.55,0.12),(-0.05,0.12),(-0.3,1),(0.6,-0.15),(0.08,-0.15),(0.45,-1)])(x,y)
def leaf(x,y):
    return (abs(x)<=1-abs(y)*0+0) and ((x+0.0)**2/0.45+(y)**2/1.0)<=1 and (x*1.0+y*0.0>-1) and abs(y+x*0.35)<=1-abs(x)*0.9
def mountain(x,y): return _poly([(-1,0.9),(-0.35,-0.3),(-0.1,0.05),(0.35,-0.85),(1,0.9)])(x,y)
def house(x,y): return _poly([(-0.85,0.9),(-0.85,-0.1),(0,-0.95),(0.85,-0.1),(0.85,0.9)])(x,y)
def fish(x,y): return (x+0.15)**2/0.7**2+y*y/0.5**2<=1 or _poly([(0.45,0),(1,-0.55),(1,0.55)])(x,y)
def crown(x,y): return _poly([(-0.95,0.8),(-0.95,-0.7),(-0.45,-0.05),(0,-0.85),(0.45,-0.05),(0.95,-0.7),(0.95,0.8)])(x,y)
SHAPES=dict(star=star,heart=heart,moon=moon,diamond=diamond,hexagon=hexagon,drop=drop,bolt=bolt,leaf=leaf,mountain=mountain,house=house,fish=fish,crown=crown)

def mask_for(shape,rows,cols):
    if shape=='rect': return {(r,c) for r in range(rows) for c in range(cols)}
    f=SHAPES[shape]; m=set()
    for r in range(rows):
        for c in range(cols):
            x=(c/(cols-1))*2-1; y=(r/(rows-1))*2-1
            if f(x,y): m.add((r,c))
    # keep largest connected component
    seen=set(); best=set()
    for s in m:
        if s in seen: continue
        comp=set([s]); st=[s]; seen.add(s)
        while st:
            r,c=st.pop()
            for dr,dc in D.values():
                n=(r+dr,c+dc)
                if n in m and n not in seen: seen.add(n); comp.add(n); st.append(n)
        if len(comp)>len(best): best=comp
    return best

# ---------- generation ----------
def build(rows,cols,mask,rng,target_cov,min_len,max_len,turn_bias,min_depth,spacing=0,max_threads=None):
    occ={}; threads=[]; rayown=defaultdict(set); free=set(mask)
    total=len(mask); fails=0
    def neighbours(n):
        r,c=n
        for dr,dc in D.values():
            m=(r+dr,c+dc)
            if m in free: yield m,(dr,dc)
    def walk(start,L):
        path=[start]; seen={start}; last=None
        for _ in range(L-1):
            opts=[(m,d) for m,d in neighbours(path[-1]) if m not in seen]
            if not opts: break
            if last is not None:
                straight=[o for o in opts if o[1]==last]
                if straight and rng.random()>turn_bias: m,d=straight[0]
                else: m,d=rng.choice(opts)
            else: m,d=rng.choice(opts)
            path.append(m); seen.add(m); last=d
        return path
    attempts=0
    while len(occ)<target_cov*total and fails<260:
        if max_threads and len(threads)>=max_threads: break
        attempts+=1
        cand=[]
        pocket=fails>40
        starts=rng.sample(sorted(free),min(len(free),10 if pocket else 6)) if free else []
        if not starts: break
        for s in starts:
            L=rng.randint(2,4) if pocket else rng.randint(min_len,max_len)
            p=walk(s,L)
            if len(p)<(2 if pocket else min_len): continue
            for cells in (p,p[::-1]):
                rr=ray(cells,rows,cols); own=set(cells)
                if any((n in occ) or (n in own) for n in rr): continue
                if spacing and any(((n[0]+dr,n[1]+dc) in occ) for n in cells for dr in range(-spacing,spacing+1) for dc in range(-spacing,spacing+1)): continue
                cross=len(set().union(*[rayown[n] for n in cells])) if cells else 0
                straight_pen=0.0
                if len(cells)>=4 and len({(b[0]-a[0],b[1]-a[1]) for a,b in zip(cells,cells[1:])})==1: straight_pen=1.2
                edge_pen=0.6 if all(n[0] in (0,rows-1) or n[1] in (0,cols-1) for n in cells) and len(cells)>3 else 0
                score=len(cells)*0.15+min(cross,3)*(1.4 if min_depth>2 else 0.7)-straight_pen-edge_pen+rng.random()*0.5
                cand.append((score,cells))
        if not cand: fails+=1; continue
        cand.sort(key=lambda x:-x[0]); cells=cand[0][1]
        tid=len(threads); threads.append(cells)
        for n in cells: occ[n]=tid; free.discard(n)
        for n in ray(cells,rows,cols): rayown[n].add(tid)
        fails=0
    # tail-extension repair
    changed=True
    while changed and len(occ)<target_cov*total+1:
        changed=False
        for n in sorted(free):
            if n not in free: continue
            for i,t in enumerate(threads):
                if len(t)>=max_len+2: continue
                a=t[0]
                if abs(a[0]-n[0])+abs(a[1]-n[1])==1:
                    nt=[n]+t
                    if any(n in ray(o,rows,cols) for j,o in enumerate(threads) if j!=i and n in set(ray(o,rows,cols))): continue
                    trial=threads[:i]+[nt]+threads[i+1:]
                    if valid(trial,rows,cols):
                        threads=trial; free.discard(n); occ[n]=i; changed=True; break
            if len(occ)>=target_cov*total: break
    occ={n:i for i,t in enumerate(threads) for n in t}
    return threads,len(occ)/total

def seed_for(ch,idx): return int(hashlib.sha1(f"unwind|{ch}|{idx}".encode()).hexdigest()[:8],16)

CHAPTERS=[
 # name, cols0, cols1, aspect0, aspect1, cov0, cov1, len(min,max0), len max1, depth0, depth1, shapes
 ("First Threads",9,11,1.15,1.25,0.26,0.38,(2,3),(2,4),2,4,[]),
 ("Loose Ends",10,12,1.2,1.35,0.36,0.48,(2,4),(2,6),3,5,['diamond','hexagon','heart','leaf']),
 ("Straight Talk",11,13,1.3,1.45,0.46,0.58,(2,5),(3,8),4,6,['mountain','house','drop','diamond']),
 ("Corners",11,14,1.35,1.5,0.56,0.68,(3,6),(3,8),5,7,['heart','fish','leaf','hexagon']),
 ("Spirals",12,15,1.4,1.55,0.64,0.74,(3,7),(4,10),5,8,['moon','drop','star','heart']),
 ("Crosscurrents",12,15,1.4,1.6,0.70,0.78,(3,7),(3,9),6,9,['bolt','fish','crown','mountain']),
 ("Dense Weave",13,16,1.45,1.65,0.76,0.84,(3,8),(3,10),7,10,['star','moon','heart','house']),
 ("Labyrinth",13,16,1.5,1.7,0.80,0.87,(3,8),(4,12),8,12,['crown','bolt','leaf','star']),
 ("Long Form",14,17,1.5,1.75,0.82,0.89,(3,9),(5,14),9,13,['moon','fish','mountain','star']),
 ("Masterworks",14,17,1.55,1.8,0.84,0.9,(3,9),(4,14),10,15,['star','moon','heart','crown','bolt']),
]
def lerp(a,b,t): return a+(b-a)*t

def make_level(ch,k,tries=60):
    name,c0,c1,a0,a1,v0,v1,l0,l1,d0,d1,shapes=CHAPTERS[ch]
    t=k/19
    cols=round(lerp(c0,c1,t)); aspect=lerp(a0,a1,t); rows=round(cols*aspect)
    shape='rect'
    if ch>=1 and (k+1)%5==0 and shapes:
        shape=shapes[((k+1)//5-1)%len(shapes)]
        cols=min(23,cols+5+ch//3); rows=round(cols*1.18)
        if shape in('moon','bolt','crown','mountain'): rows=round(cols*1.3)
    mask=mask_for(shape,rows,cols)
    cov=lerp(v0,v1,t); 
    if shape!='rect': cov=min(cov,0.88)*0.97
    minlen=l0[0]; maxlen=round(lerp(l0[1],l1[1],t))
    if shape!='rect': maxlen=min(maxlen,7); minlen=min(minlen,3)
    turn=lerp(0.35,0.62,min(1,ch/6))
    if ch==4: turn=0.8
    min_depth=round(lerp(d0,d1,t)); spacing=1 if (ch==0 and k<12) else 0
    best=None
    for tr in range(tries):
        rng=random.Random(seed_for(ch+1,k+1)+tr*7919)
        threads,cv=build(rows,cols,mask,rng,cov,minlen,maxlen,turn,min_depth,spacing)
        if not valid(threads,rows,cols): continue
        depth,free0=solve(threads,rows,cols)
        n=len(threads)
        ok_free= free0>=2 and (ch<2 or free0<=max(3,0.4*n))
        if ch==0 and k<5: ok_free = free0>=2
        mind=max(2,min_depth-1) if ch>0 else (2 if k<5 else 3)
        score=cv*3+min(depth,min_depth+2)*0.35-(0 if ok_free else 3)-(0 if depth>=mind else 3)
        if ch==0: 
            lo=6+k//2; hi=9+k
            score-= 0 if lo<=n<=hi else 2
        if best is None or score>best[0]: best=(score,threads,cv,depth,free0,tr)
        if score>cov*3+min_depth*0.35+0.3 and ok_free and depth>=mind: break
    score,threads,cv,depth,free0,tr=best
    return dict(id=ch*20+k+1,rows=rows,cols=cols,shape=shape,par=0,threads=[[list(n) for n in t] for t in threads]),dict(cov=cv,depth=depth,free0=free0,tries=tr+1,n=len(threads))

if __name__=="__main__":
    import os
    out=sys.argv[1] if len(sys.argv)>1 else "levels"; os.makedirs(out,exist_ok=True)
    chs=[int(x) for x in sys.argv[2].split(',')] if len(sys.argv)>2 else range(10)
    report=["| Level | Grid | Shape | Threads | Coverage | Depth | Free at start |","|---|---|---|---|---|---|---|"]
    for ch in chs:
        levels=[]
        for k in range(20):
            lv,st=make_level(ch,k); levels.append(lv)
            assert valid([[tuple(n) for n in t] for t in lv['threads']],lv['rows'],lv['cols'])
            report.append(f"| {lv['id']} | {lv['cols']}x{lv['rows']} | {lv['shape']} | {st['n']} | {st['cov']*100:.0f}% | {st['depth']} | {st['free0']} |")
            print(report[-1],flush=True)
        json.dump(dict(v=1,chapter=ch+1,name=CHAPTERS[ch][0],levels=levels),open(f"{out}/chapter_{ch+1:02d}.json","w"),separators=(',',':'))
    open(f"{out}/level_report.md","a").write("\n".join(report)+"\n")
