let c=0;

function carrusel(){

    let imagen = document.getElementById("baner");
    c++;
    if(c>10) c=1;
    imagen.setAttribute("src","imagenes/banner" + c + ".jpg");
}

setInterval(carrusel,1000)