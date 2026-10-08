import json,sys,math
from PIL import Image,ImageDraw
THEMES={'sage':dict(bg='#ECEEE4',ink='#25302A',dot='#C9CEBF',acc='#55774E',muted='#5D6757')}
def render(level,path,theme='sage',W=720,H=1440,scale=1):
    t=THEMES[theme]; im=Image.new('RGB',(W,H),t['bg']); d=ImageDraw.Draw(im)
    rows,cols=level['rows'],level['cols']
    pad=int(W*0.075); top=int(H*0.115); bottom=int(H*0.10)
    cell=min((W-2*pad)/(cols-1),(H-top-bottom-60)/(rows-1),int(W*0.13))
    bw=cell*(cols-1); bh=cell*(rows-1)
    ox=(W-bw)/2; oy=top+((H-top-bottom-60)-bh)/2-8
    sw=max(3,min(cell*0.075,6)); arm=max(8,min(cell*0.23,22))
    for r in range(rows):
        for c in range(cols):
            x=ox+c*cell;y=oy+r*cell; d.ellipse([x-2.5,y-2.5,x+2.5,y+2.5],fill=t['dot'])
    for th in level['threads']:
        pts=[(ox+c*cell,oy+r*cell) for r,c in th]
        d.line(pts,fill=t['ink'],width=int(sw),joint='curve')
        for p in (pts[0],pts[-1]):
            d.ellipse([p[0]-sw/2,p[1]-sw/2,p[1]*0+p[0]+sw/2,p[1]+sw/2],fill=t['ink'])
        (x0,y0),(x1,y1)=pts[-2],pts[-1]; a=math.atan2(y1-y0,x1-x0)
        for s in (-1,1):
            ang=a+math.pi+s*math.radians(42)
            d.line([(x1,y1),(x1+arm*math.cos(ang),y1+arm*math.sin(ang))],fill=t['ink'],width=int(sw))
            d.ellipse([x1+arm*math.cos(ang)-sw/2,y1+arm*math.sin(ang)-sw/2,x1+arm*math.cos(ang)+sw/2,y1+arm*math.sin(ang)+sw/2],fill=t['ink'])
    # chrome
    d.line([(pad,top-20),(W-pad,top-20)],fill=t['dot'],width=2)
    d.text((pad,top-70),f"Level {level['id']}",fill=t['ink']); d.text((W-pad-90,top-70),f"{len(level['threads'])} of {len(level['threads'])}",fill=t['muted'])
    d.line([(pad,H-bottom)]+[(W-pad,H-bottom)],fill=t['dot'],width=2)
    d.text((pad,H-bottom+30),"Restart",fill=t['muted']); d.text((W//2-20,H-bottom+30),"Hint",fill=t['muted']); d.text((W-pad-90,H-bottom+30),"How to play",fill=t['muted'])
    im.save(path)
if __name__=="__main__":
    ch=json.load(open(sys.argv[1])); ids=[int(x) for x in sys.argv[3].split(',')]
    for lv in ch['levels']:
        if lv['id'] in ids: render(lv,f"{sys.argv[2]}/level_{lv['id']:03d}.png")
