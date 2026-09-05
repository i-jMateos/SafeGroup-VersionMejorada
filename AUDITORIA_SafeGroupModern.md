# Auditoría técnica — SafeGroupModern (app iOS "SafeGroup")

**Fecha:** 3 de septiembre de 2026
**Alcance:** repositorio local `SafeGroupModern` (Xcode + CocoaPods, Swift, Firebase Auth/Firestore/Storage). Revisión estática de las ~3.000 líneas de Swift, `Podfile`/`Podfile.lock`, `Info.plist` y configuración del proyecto. Historial de git: solo 2 commits ("Initial SafeGroupModern import" y "Fix SafeGroupModern build with updated dependencies"), y `RegisterViewController.swift` tiene un cambio sin commitear (añade `import FirebaseFirestore`).

**No incluido en esta auditoría** (fuera de mi alcance en el repo): reglas de seguridad de Firestore/Storage — no hay ningún fichero `.rules` en el proyecto, así que no he podido revisarlas; habría que exportarlas desde la consola de Firebase.

Sobre lo que comentabas de P2PKit: confirmado, sigue "arreglado" tal y como lo dejasteis — está completamente **mockeado y desactivado** (ver hallazgo 1). No he encontrado el chat anterior porque no tengo acceso al historial de otras conversaciones, así que esta auditoría parte de cero sobre el estado actual del código.

---

## Resumen ejecutivo

La app compila y sigue una arquitectura MVC de Xcode clásica, razonable para su tamaño. El problema más serio no es de estilo sino de **funcionalidad central**: la característica que da sentido a "SafeGroup" —detectar por Bluetooth qué participantes están cerca o se han perdido— está desactivada por completo desde el "fix" de build. A eso se suman varios problemas de seguridad de configuración (ATS desactivado, autorización solo en cliente), un bug de captura de ubicación que hace que las alertas de "me he perdido" reporten coordenadas (0,0), y un patrón de consultas a Firestore frágil que puede hacer que el muro y las alertas dejen de mostrar resultados sin previo aviso.

---

## Hallazgos críticos

### 1. El descubrimiento de proximidad (P2PKit) está completamente deshabilitado
`SafeGroup/Controller/ActiveEventViewController.swift:16-52`

`#import <P2PKit/P2PKit.h>` está comentado en `Bridging-Header.h:12`, y en su lugar hay un `PPKController` local que es un mock vacío:

```swift
final class PPKController {
    static func isEnabled() -> Bool { false }
    static func enable(...) {}
    ...
}
```

`isEnabled()` devuelve siempre `false`, así que en `viewDidLoad` nunca se llama a `enable()`/`enableProximityRanging()`, y todos los botones de "iniciar escucha" o descubrimiento no hacen nada. Esto es, con toda probabilidad, lo que hicisteis para que el proyecto compilara (P2PKit ya no estaba disponible/mantenido). El efecto: la pantalla de "Evento activo", el grafo de proximidad y las alertas automáticas por pérdida de contacto Bluetooth **no funcionan en absoluto** — solo funcionan las alertas manuales ("Me he perdido" pulsado a mano). Si el objetivo del proyecto sigue siendo ese, hace falta sustituir P2PKit por otra solución (MultipeerConnectivity de Apple es la alternativa nativa más directa para descubrimiento por proximidad).

### 2. App Transport Security desactivado globalmente
`SafeGroup/Info.plist:24-26`

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

Esto permite conexiones HTTP sin cifrar a cualquier dominio desde toda la app. Firebase ya usa HTTPS por defecto, así que no hay ninguna razón visible para tenerlo activado — probablemente quedó de alguna depuración. Es también un motivo típico de rechazo o de preguntas en la revisión de App Store. Recomendación: quitarlo, y si algún recurso concreto necesita HTTP, usar una excepción por dominio (`NSExceptionDomains`).

### 3. Falta la clave de privacidad de la librería de fotos → probable crash
`SafeGroup/Info.plist`

El `Info.plist` tiene `NSAppleMusicUsageDescription` (línea 28) pero **no** tiene `NSPhotoLibraryUsageDescription`. `CreateEventViewController` abre `UIImagePickerController` con `.photoLibrary` (línea ~"Photo Library" action). Sin `NSPhotoLibraryUsageDescription`, iOS mata la app al intentar acceder a la librería de fotos. Parece un copia-pega del key equivocado (Apple Music en vez de Photo Library).

### 4. La autorización solo existe en el cliente; no hay reglas de Firestore en el repo
`EventDetailsViewController.swift:60-115`

Comprobaciones como "¿soy el organizador?" (`user.email == event.user.email`) o "¿estoy inscrito?" solo se hacen en Swift, para decidir qué botón mostrar. Eso está bien como UX, pero si las reglas de seguridad de Firestore no imponen las mismas restricciones en el servidor, cualquier usuario autenticado podría, llamando directamente a la API de Firestore (sin pasar por la app), borrar eventos ajenos o reescribir el array `participants` de cualquier evento. No puedo verificar esto porque las reglas no están en el repo — es importante revisarlas en la consola de Firebase y confirmar que exigen `request.auth.uid == resource.data.user.id` (o equivalente) para escritura/borrado.

---

## Hallazgos altos

### 5. La ubicación en las alertas "Me he perdido" casi siempre es (0, 0)
`ActiveEventViewController.swift:363-364` y `438-439`

```swift
let latitude = CLLocationManager().location?.coordinate.latitude ?? 0
let longitude = CLLocationManager().location?.coordinate.longitude ?? 0
```

Se crea un `CLLocationManager()` nuevo y se lee `.location` en el mismo instante, sin haber llamado nunca a `startUpdatingLocation()` en ese manager. Un `CLLocationManager` recién creado casi siempre tiene `.location == nil` (no ha tenido tiempo de obtener un fix), así que el `?? 0` se activa y la alerta guarda latitud/longitud 0,0 (en medio del Atlántico). Esto rompe la función de seguridad más importante de la app: localizar a quien se ha perdido. Debería reutilizar el `CLLocationManager` ya activo de `EventsMapViewController`/una ubicación compartida, o usar `.location` del manager que ya está haciendo `startUpdatingLocation()`.

### 6. Condición de carrera al inscribirse/desinscribirse de un evento (lost update)
`EventDetailsViewController.swift:120-152`

```swift
var participants = event.participants ?? []
participants.removeAll(where: { $0.email == user.email })
let mappedParticipants = participants.map({ $0.dictionary })
db.collection("events").document(self.event.id).updateData(["participants": mappedParticipants])
```

El array completo de participantes se lee del estado local (`event.participants`, cargado cuando se abrió la pantalla) y se sobrescribe entero. Si dos personas se inscriben casi a la vez, la segunda escritura pisa a la primera y una de las dos inscripciones se pierde silenciosamente. Debería usarse `FieldValue.arrayUnion([...])` / `arrayRemove([...])`, que son atómicos en el servidor, en vez de leer-modificar-escribir el array completo desde el cliente.

### 7. El ID del documento de usuario en Firestore no coincide con el UID de Auth
`RegisterViewController.swift:32` vs `LoginViewController.swift:33`

```swift
usersReference = db.collection("users").document()   // ID aleatorio, no el UID
...
let userReference = Firestore.firestore().collection("users").whereField("id", isEqualTo: authResult?.user.uid ?? "")
```

Al registrar, el documento de usuario se crea con un ID autogenerado por Firestore en vez de usar el UID de Firebase Auth como ID del documento (`db.collection("users").document(id)`). Por eso el login tiene que hacer una *query* (`whereField`) en vez de un `get()` directo por ID, lo cual es más lento, más caro y hace mucho más difícil escribir reglas de seguridad idiomáticas del tipo "solo el propio usuario puede leer/escribir su documento" (`request.auth.uid == resource.id`). Vale la pena migrar a usar el UID como ID del documento.

### 8. El muro de eventos y las alertas consultan Firestore comparando el objeto `Event` completo
`WallViewController.swift:62`, `EventAlertsViewController.swift:38`

```swift
.whereField("event", isEqualTo: eventDict)
```

`eventDict` es el diccionario completo del evento actual en memoria (incluye `participants`, `imageUrl`, fechas, etc.). Firestore compara esto como igualdad exacta del mapa entero. En cuanto el evento cambie mínimamente entre el momento en que se creó un post/alerta y el momento en que se vuelve a consultar (por ejemplo, se inscribe un nuevo participante, cambia `imageUrl`...), la comparación deja de coincidir y **la consulta devuelve cero resultados sin ningún error visible** — el muro o las alertas aparecerán vacíos aunque haya datos. Debería guardarse y consultarse por un campo simple como `eventId` (`whereField("eventId", isEqualTo: event.id)`), no por el objeto completo.

### 9. No se puede crear un evento si no se ha elegido imagen
`CreateEventViewController.swift:166` (`createEventButton`)

Todo el flujo de guardado (`createEvent`, subida a Storage, etc.) está anidado dentro de:
```swift
if let imageData = self.eventImageView.image?.jpegData(compressionQuality: 80) {
    ...
}
```
Si el usuario no ha seleccionado ninguna imagen, este bloque no se ejecuta, `self.showLoading(...)` ya se había llamado justo antes pero `removeLoading()` nunca se llama (solo se llama dentro del bloque), así que el spinner de carga se queda visible indefinidamente y el evento no se crea, sin ningún mensaje de error. Habría que hacer que la imagen sea opcional y separar "crear evento" de "subir imagen si existe".

---

## Hallazgos medios

### 10. Doble solicitud de permisos de ubicación contradictoria
`EventsMapViewController.swift:44, 101, 108`

Se llama a `requestAlwaysAuthorization()` en `determineUserLocation()` y, justo después (en `viewDidAppear`), a `requestWhenInUseAuthorization()` dos veces más en `setupUserLocation()` (una en el manager de la clase y otra en un `CLLocationManager()` local nuevo). Pedir "Always" y luego "When In Use" seguidos puede confundir el flujo de permisos de iOS y no está claro cuál prevalece. Conviene decidir un único flujo de permisos y limpiar el resto.

### 11. Sin validación de entradas antes de llamar a Firebase Auth
`LoginViewController.swift` / `RegisterViewController.swift`

`email`/`password` se toman del `UITextField` con `?? ""` y se envían directamente a `Auth.auth().signIn`/`createUser` sin comprobar formato de email, longitud mínima de contraseña, ni campos vacíos. Firebase rechazará casos obviamente inválidos, pero el usuario solo verá el error crudo de Firebase (si es que lo ve — ver punto 12), no un mensaje claro en español acorde al resto de la UI.

### 12. Los errores solo se imprimen por consola, nunca se muestran al usuario
Patrón repetido en casi todos los `completion` de Firebase (`print(error)`, `print("Error adding document: \(err)")`...). El usuario no se entera si el login falla, si no se pudo crear el evento, etc. Sería importante centralizar el manejo de errores y mostrar una alerta.

### 13. Doble pulsación en Login/Registro/Crear evento puede duplicar peticiones
Los botones (`loginButton`, `registerButton`, `createEventButton`...) no se deshabilitan mientras la llamada asíncrona está en curso, así que un doble tap puede disparar dos `createUser`/`setData` en paralelo.

### 14. Uso extendido de force-unwrap / force-cast
Ejemplos: `UIApplication.shared.delegate as! AppDelegate` (repetido en `LoginViewController`, `RegisterViewController`, `UserProfileViewController`), `User.currentUser!` en `ActiveEventViewController.peerLost`, `querySnapshot!.documents`. Cualquiera de estos puede provocar un crash si el supuesto no se cumple (por ejemplo, `User.currentUser` es `nil` porque `AppDelegate` no restauró la sesión).

### 15. Lógica de navegación post-login/registro/logout duplicada tres veces
`LoginViewController`, `RegisterViewController` y `UserProfileViewController` repiten literalmente el mismo bloque para instanciar `Main`/`Login` storyboard y asignarlo como `rootViewController`. Merece extraerse a un método común (por ejemplo en `AppDelegate` o un `SceneCoordinator`).

### 16. La descripción del evento se concatena con los emails de los participantes sin separador
`EventDetailsViewController.swift` (`setupView`):
```swift
descriptionTextView.text = event.description + participants
```
Sin salto de línea ni etiqueta, el texto queda pegado ("...fin de la descripción juan@x.com : ana@y.com"). Además, expone los emails de todos los inscritos a cualquiera que vea el detalle del evento, lo cual conviene revisar desde el punto de vista de privacidad (¿deberían verse los emails de otros participantes?).

### 17. La condición para ocultar "Registrarme" probablemente está invertida
`EventDetailsViewController.swift:78`
```swift
actionButton.isHidden = event.endDate <= Date() && event.startDate <= Date()
```
Con `&&`, el botón solo se oculta cuando el evento ya **terminó** (empezó y acabó en el pasado). Mientras el evento está en curso (empezó pero no ha acabado), el botón de inscripción sigue visible, permitiendo inscribirse a un evento ya empezado. Si la intención era impedir inscripciones una vez iniciado el evento, la condición debería ser solo `event.startDate <= Date()`.

### 18. Sin paginación ni límites en las lecturas de Firestore
`getEvents()` (mapa), `getMyEvents()`, `getPosts()`, `getAlertsForEvent()` traen la colección entera cada vez con `.getDocuments()`. Funciona con pocos datos, pero crecerá en coste (lecturas facturables de Firestore) y en tiempo de carga a medida que haya más eventos/usuarios.

---

## Hallazgos menores / calidad de código

- **Código muerto:** `Register.swift` define `class register` (con contraseña en texto plano como propiedad) que no se instancia en ningún sitio — el registro real usa la función `register(...)` de `RegisterViewController`. Y `Model/EventCreateViewController.swift` es un controlador vacío no referenciado por ningún storyboard (el que sí se usa es `Controller/CreateEventViewController.swift`). Ambos deberían eliminarse para evitar confusión.
- **Errores tipográficos consistentes en el modelo de datos:** `firtname` en vez de `firstname` (parámetros de `User`/`register`), `localitation` en vez de `location`/`localización` (en `Event`, `EventAlert`). No rompen nada, pero conviene corregirlos antes de que el equipo crezca, ya que están muy extendidos por el código.
- **`Event.encode(to:)` codifica `description` dos veces** (`Event.swift:48-49`) — no rompe nada porque es la misma key, pero sugiere que falta codificar otro campo o es un copia-pega sin limpiar.
- **Deployment target inconsistente:** a nivel de proyecto Xcode está en iOS 10.3, pero el target y el `Podfile` exigen iOS 12.0 (y el `post_install` fuerza 12.0 en los Pods). No rompe la build porque el target manda, pero es una configuración confusa a limpiar.
- **Permisos de Bluetooth en background solicitados sin uso real:** `UIBackgroundModes` declara `bluetooth-central` y `bluetooth-peripheral` (para P2PKit), pero como ese subsistema está deshabilitado (hallazgo 1), la app pide permisos de Bluetooth en segundo plano que no usa para nada — esto puede generar dudas en la revisión de App Store y preocupación innecesaria en el usuario.
- **Firebase SDK en 10.29.0** (según `Podfile.lock`), una versión de mediados de 2024. No es una vulnerabilidad conocida, pero conviene actualizar periódicamente con `pod update Firebase`.
- La API key de `GoogleService-Info.plist` está en el repo — esto es el patrón normal y esperado para apps iOS con Firebase (no es un secreto que deba ocultarse), pero recuerda que la seguridad real depende enteramente de las reglas de Firestore/Storage del hallazgo 4, no de ocultar esta clave.

---

## Recomendaciones priorizadas

1. Decidir el futuro de la funcionalidad de proximidad: o se reemplaza P2PKit por `MultipeerConnectivity` (nativo de Apple, gratuito) u otra alternativa, o se retira honestamente esa parte de la UI/permisos mientras no esté disponible.
2. Revisar y exportar las reglas de seguridad de Firestore/Storage desde la consola de Firebase, y alinear los IDs de documento de usuario con el UID de Auth para poder escribir reglas del tipo "solo el dueño puede escribir".
3. Arreglar la captura de ubicación en las alertas (hallazgo 5) — es el bug más grave desde el punto de vista de la promesa de seguridad de la app.
4. Quitar `NSAllowsArbitraryLoads` y añadir `NSPhotoLibraryUsageDescription`.
5. Cambiar las consultas de "muro" y "alertas" para filtrar por `eventId` en vez de por el objeto `Event` completo.
6. Sustituir las escrituras de `participants` por `FieldValue.arrayUnion`/`arrayRemove`.
7. Añadir manejo de errores visible al usuario y deshabilitar botones durante llamadas async, en login/registro/creación de evento.
8. Limpieza de código muerto (`Register.swift`, `Model/EventCreateViewController.swift`) y de la duplicación de navegación post-login/registro/logout.
