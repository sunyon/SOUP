pro idl_points



data1=read_ascii('/sceos2_data1/data/land_use/sa/davet/6min/lat_lon2.dat')




data2=read_ascii('/sceos2_data1/data/land_use/sa/davet/6min/cont_lu-31-2000.dat')
stf=               '/sceos2_data1/data/land_use/sa/davet/6min/maps2/31.ps'
st1=tag_names(data1)
print,tag_names(data1)
res = size(data1.field1)
no = res(2)
lats=fltarr(no)
lons=fltarr(no)
vals=fltarr(no)
for i=0l,no-1 do lats(i) = data1.field1(0,i)
for i=0l,no-1 do lons(i) = data1.field1(1,i)
for i=0l,no-1 do vals(i) = data2.field1(i)
b = vals eq 255
vals = vals - b*255
xpag = 29.7
ypag = 21.0
xoff=0.0
yoff=29.7

set_plot,'ps'
device, /landscape, /color, bits_per_pixel=8, filename=stf, xoffset = xoff, yoffset = yoff
usersym,[-1,0,1,0,-1],[0,1,0,-1,0],/fill
usersym,[-1,-1,1,1,-1],[-1,1,1,-1,-1],/fill
rct,'ct/diff'
rct,'ct/prc'
xw = 1.0
yw = 1.0
x0 = 0.6
y0 = 0.6
sc0 =0.0
scf =100.0
nocol = 10.0
vals = vals < scf
vals = vals > sc0
map_set, /isotropic, /continents, /hires,  position=[x0-xw/2.0,y0-yw/2.0,x0+xw/2.0,y0+yw/2.0], limit=[-36,16,-20,34], color=5
for i=0l,no-1 do if (vals(i) > sc0) then  plots,lons(i),lats(i),color=(vals(i)-sc0)/(scf-sc0)*16.0*nocol+16.0,psym=8,symsize=0.45
map_grid, latdel = 1, londel = 1, color = 5, label = 2, latlab = 16, lonlab = -35, latalign = 0.5, lonalign = 0.5, /box_axes
device, /close
set_plot,'x'





return
end
