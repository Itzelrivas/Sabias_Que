# ¿Sabías qué? – App iOS en Objective-C

Aplicación de una sola pantalla que permite conocer datos curiosos de diferentes temas de interés con un solo toque.

## Funcionamiento

1. El usuario **selecciona una de tres categorías**: Ciencia, Historia o Tecnología.
2. Al **tocar el botón** «Mostrar dato curioso» se despliega un dato curioso de la categoría elegida.
3. Al **tocar nuevamente el botón** («Otro dato curioso») se muestra **información diferente** de la misma categoría.

Detalles de comportamiento:

- El botón permanece deshabilitado hasta que se elige una categoría.
- Cada categoría tiene 8 datos. Se muestran en orden aleatorio **sin repetirse** hasta agotarlos; al reiniciar el ciclo nunca se repite el último dato de forma consecutiva.
- Al cambiar de categoría se reinicia el recorrido y el contador («Dato X de 8»).
- Funciona sin conexión a internet (los datos son locales).
- Soporta modo oscuro, tamaño de letra dinámico (Dynamic Type) y VoiceOver.

## Requisitos

- macOS con **Xcode 14 o superior**.
- Objetivo mínimo de despliegue: **iOS 13.0** (iPhone y iPad).

## Cómo abrirlo y ejecutarlo

1. Descomprime el `.zip`.
2. Abre `SabiasQue/SabiasQue.xcodeproj` con Xcode.
3. Elige un simulador de iPhone (por ejemplo, *iPhone 15*) en la barra superior.
4. Presiona **▶ Run** (⌘R).

> Para correrlo en un iPhone físico: en *Signing & Capabilities* selecciona tu equipo (Team) personal y, si es necesario, cambia el *Bundle Identifier* (`mx.uveg.SabiasQue`) por uno único.

## Estructura del proyecto

```
SabiasQue/
├── SabiasQue.xcodeproj          Proyecto de Xcode
└── SabiasQue/
    ├── main.m                   Punto de entrada de la app
    ├── AppDelegate.h/.m         Crea la ventana y la pantalla principal
    ├── ViewController.h/.m      Interfaz (por código, Auto Layout) y lógica de la pantalla
    ├── FactsStore.h/.m          Modelo: categorías, datos curiosos y lógica para no repetirlos
    ├── Info.plist               Configuración de la app
    └── Assets.xcassets          Ícono de la app y color de acento
```

## Arquitectura (patrón MVC)

| Capa | Clase | Responsabilidad |
|------|-------|-----------------|
| Modelo | `FactsStore` | Almacena las 3 categorías y sus datos; entrega el siguiente dato sin repetir. |
| Vista | Vistas UIKit creadas en `ViewController` | `UILabel`, `UISegmentedControl`, tarjeta (`UIView`) y `UIButton`. |
| Controlador | `ViewController` | Responde a los toques, consulta al modelo y actualiza la interfaz. |

## Autor

Reto 3 – Diseño y desarrollo de aplicación iOS · Desarrollo de aplicaciones móviles en iOS.
