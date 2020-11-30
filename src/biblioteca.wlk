import wollok.game.*


class MovimientoRectangular {
	const filaDesde = 0
	const filaHasta = game.height()-1
	const columnaDesde = 0
	const columnaHasta = game.width()-1
	
	method configurarFlechas(visual){
		keyboard.up().onPressDo{ self.mover(arriba,visual)}
		keyboard.down().onPressDo{ self.mover(abajo,visual)}
		keyboard.left().onPressDo{ self.mover(izquierda,visual)}
		keyboard.right().onPressDo{ self.mover(derecha,visual)}
	}
	
	method mover(direccion,personaje){
		const destino = direccion.siguiente(personaje.position())
		if (self.esValido(destino))
			personaje.position(destino)
	}	
	
	method esValido(posicion) =
		posicion.y().between(filaDesde,filaHasta) and
		posicion.x().between(columnaDesde,columnaHasta)
}

object izquierda { 
	method siguiente(position) = position.left(1) 
}

object derecha { 
	method siguiente(position) = position.right(1) 
}

object abajo { 
	method siguiente(position) = position.down(1) 
}

object arriba { 
	method siguiente(position) = position.up(1) 
}


class VisualizadorNumerico {
	const cantCifras 
	var position
	var origen
	const frecuencia = 250 // Agregado para mejorar performance
	var valor = 0
	
	method configurar(){
		cantCifras.times{i=>
			game.addVisual(new Cifra(
				position=position.right(i-1),
				contenedor = self,
				digito = cantCifras - i + 1
			))
		}
		self.actualizar()
		game.onTick(frecuencia,"actualizacion",{self.actualizar()})
	}
	method actualizar() {
		valor = origen.apply()
	}
	method valor() = valor
}

class Cifra {
	var property position
	var contenedor 
	var digito
	
	method image() = "nro" + self.valor().toString() + ".png"
	
	method valor() = contenedor.valor().rem(10**digito).div(10**(digito-1))
}
