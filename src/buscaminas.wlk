/** First Wollok example */
import wollok.game.*
import biblioteca.*

const facil = 10 

object buscaminas {
	const property celdas = []
	const ancho = 10
	const alto = 10
	const dificultad = facil
	var property estado = esperando
	var abiertas = 0
	
	method iniciar(){
		self.configurarTablero()
		self.crearCeldas()
		self.ubicarMinas()
		celdas.forEach{celda=>game.addVisual(celda)}
		game.addVisual(resultado)
		game.addVisual(cursor)
		self.configurarTeclas()
		self.desplegarContadorBanderas()
		self.desplegarReloj()
	}
	
	method reiniciar(){
		self.resetearCeldas()
		self.ubicarMinas()
		estado = esperando
		abiertas = 0
		reloj.resetear()
	}
	method configurarTablero(){
		game.width(ancho)
		game.height(alto+1)
		game.cellSize(75)
		game.title("Buscaminas - <space> descubrir / volver a jugar - <enter> marcar bandera")
	}
	method resetearCeldas(){
		celdas.forEach{celda=>celda.resetear()}
	}
	method crearCeldas() {
		alto.times{fila=> 
			ancho.times{columna=>
				celdas.add(new Celda(position = game.at(columna-1,fila-1)))
			}
		}
		celdas.forEach{celda=>celda.setearLinderas()}
	}
	method ubicarMinas() {
		dificultad.times{i=>
			self.celdasSinMinas().anyOne().ponerMina()
		}
	}
	
	method celdaEn(pos) =
		celdas.find{celda=> celda.position() == pos}
	
	method configurarTeclas(){
		keyboard.enter().onPressDo{estado.clickDerecho()}
		keyboard.space().onPressDo{estado.clickIzquierdo()}
		new MovimientoRectangular(filaHasta = alto-1).configurarFlechas(cursor)
	}
	
	method descubrioTodo() =
		abiertas == ancho*alto-dificultad	
	//	self.celdasSinMinas().all{celda=>celda.abierta()} menos performante

	method celdasSinMinas() = celdas.filter{celda=> !celda.tieneMina()}
	method celdasConMinas() = celdas.filter{celda=> celda.tieneMina()}
	
	method perder() {
		estado = perdio
		self.celdasConMinas().forEach{celda=>celda.estado(abierta)}
		self.celdasConBanderasEquivocadas().forEach{celda=>celda.estado(banderaEquivocada)}
		reloj.detener()
	}
	method ganar() {
		estado = gano
		self.celdasConMinas().forEach{celda=>celda.estado(bandera)}
		reloj.detener()
	}
	method celdasConBanderasEquivocadas() =
		celdas.filter{celda=>celda.banderaEquivocada()}
	
	method desplegarContadorBanderas(){
		new VisualizadorNumerico(
			cantCifras = 2, 
			position = game.at(0,game.height()-1),
			origen = {self.cantidadBanderas()}
		).configurar()
	}
	method desplegarReloj(){
		new VisualizadorNumerico(
			cantCifras = 3, 
			position = game.at(game.width()-3,game.height()-1),
			origen = {reloj.segundos()}
		).configurar()
	}
	method cantidadBanderas()=
		dificultad - celdas.count{celda=>celda.estado()==bandera}
	
	method contarAbierta() {
		abiertas +=1
	}
}

object resultado {
	method position() = game.at(game.width()/2-1,game.height()-1)
	method image() = buscaminas.estado().imagen() + ".png"
}

class Estado {
	const property imagen
	method clickIzquierdo() {
		buscaminas.reiniciar()
	}
	method clickDerecho() {}
}

object jugando inherits Estado(imagen = "jugando") {
	override method clickIzquierdo(){
		cursor.clickIzquierdo()
	}
	override method clickDerecho(){
		cursor.clickDerecho()
	}
}
	
object esperando inherits Estado(imagen = "esperando") {
	override method clickIzquierdo(){
		reloj.iniciar()
		buscaminas.estado(jugando)
		cursor.clickIzquierdo()
	}
}	
	
const gano = new Estado(imagen = "gano")
const perdio = new Estado(imagen = "perdio")

object cursor {
	var property position = game.center()
	
	method image() = "cursor.png"
	
	method clickDerecho(){
		buscaminas.celdaEn(position).clickDerecho()
	}
	method clickIzquierdo(){
		buscaminas.celdaEn(position).clickIzquierdo()
	}	
}

class Celda {
	var property position
	var celdasLinderas = null
	var property estado = nada
	var property tieneMina = false
	var valor = 0
	
	method image() = estado.imagen(self) + ".png"

	method imagenAbierta() = if (tieneMina) "mina" else valor.toString() 
	
	method ponerMina() {
		tieneMina = true
		celdasLinderas.forEach{celda=>celda.contarMina()}
	}
	method setearLinderas() {
		celdasLinderas = buscaminas.celdas().filter{celda=>self.esLinderaDe(celda)}
	}
	method contarMina() {
		valor += 1
	}
	method abrir() {
		estado = abierta
		buscaminas.contarAbierta()
		if (tieneMina)
			buscaminas.perder()
		else {
			if (valor == 0 ) 
//				self.celdasLinderasCerradas().forEach{celda=>celda.abrir()}  no es correcto, se van modifican cuales son las celdas cerradas 
				celdasLinderas.forEach{celda=>if(!celda.abierta()) celda.abrir()}
			if (buscaminas.descubrioTodo())
				buscaminas.ganar()			
		}
	}
 	
	method esLinderaDe(celda) =
		celda != self and
		(celda.position().x() - position.x()).abs() <=1 and
		(celda.position().y() - position.y()).abs() <=1
	
	method celdasLinderasCerradas() =
		celdasLinderas.filter{celda=>!celda.abierta()}
		
	method clickIzquierdo(){
		estado.clickIzquierdo(self) 
	}
	method clickDerecho(){
		estado = estado.marca()
	}
	method abierta() = estado == abierta
	
	method banderaEquivocada() = estado == bandera && !tieneMina
	
	method resetear(){
		estado = nada
		tieneMina = false
		valor = 0
	}
}

object abierta {
	method imagen(celda) = celda.imagenAbierta()
	method marca() = self
	method clickIzquierdo(celda) {}
}

object nada {
	method imagen(_) = "nada"
	method clickIzquierdo(celda) {celda.abrir()}
	method marca() = bandera
}

object bandera {
	method imagen(_) = "bandera"
	method clickIzquierdo(celda) {}
	method marca() = nada
}

object banderaEquivocada {
	method imagen(_) = "banderaEquivocada"
	method clickIzquierdo(celda) {}
	method marca() = self
}


object reloj {
	var property segundos = 0
	
	method iniciar(){
		game.onTick(1000,"reloj",{self.pasoUnSegundo() }
		)
	}
	method pasoUnSegundo(){
		segundos +=1
	}
	method detener(){
		game.removeTickEvent("reloj")
	}
	method resetear(){
		segundos = 0
	}
}

