//
//  FactsStore.m
//  SabiasQue
//

#import "FactsStore.h"

static NSString * const kNameKey  = @"name";
static NSString * const kEmojiKey = @"emoji";
static NSString * const kFactsKey = @"facts";

@interface FactsStore ()

/// Arreglo de diccionarios: nombre, emoji y datos de cada categoría.
@property (nonatomic, strong) NSArray<NSDictionary *> *categories;

/// Orden aleatorio vigente de los datos de cada categoría (clave: índice de categoría).
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSMutableArray<NSNumber *> *> *orders;

/// Posición actual dentro del orden de cada categoría.
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSNumber *> *cursors;

/// Último dato mostrado de cada categoría (para no repetirlo al reiniciar el ciclo).
@property (nonatomic, strong) NSMutableDictionary<NSNumber *, NSNumber *> *lastFactIndexes;

@end

@implementation FactsStore

- (instancetype)init {
    self = [super init];
    if (self) {
        _orders = [NSMutableDictionary dictionary];
        _cursors = [NSMutableDictionary dictionary];
        _lastFactIndexes = [NSMutableDictionary dictionary];
        _categories = @[
            @{
                kNameKey: @"Ciencia",
                kEmojiKey: @"🔬",
                kFactsKey: @[
                    @"Un día en Venus dura más que su propio año: el planeta tarda unos 243 días terrestres en girar sobre sí mismo y solo 225 en dar la vuelta al Sol.",
                    @"La luz del Sol tarda aproximadamente 8 minutos y 20 segundos en llegar hasta la Tierra.",
                    @"Alrededor del 60 % del cuerpo de un adulto está compuesto por agua.",
                    @"Los plátanos son ligeramente radiactivos porque contienen potasio-40, un isótopo natural. No representan ningún riesgo para la salud.",
                    @"El diamante y el grafito de un lápiz están hechos del mismo elemento, el carbono; lo único que cambia es la forma en que se ordenan sus átomos.",
                    @"En Marte los atardeceres se ven azulados, justo lo contrario a lo que ocurre en la Tierra.",
                    @"Un rayo puede calentar el aire que lo rodea hasta unos 30 000 °C, cinco veces más que la temperatura de la superficie del Sol.",
                    @"Gracias a su baja humedad y alta acidez, la miel bien almacenada puede conservarse durante años sin echarse a perder."
                ]
            },
            @{
                kNameKey: @"Historia",
                kEmojiKey: @"🏛️",
                kFactsKey: @[
                    @"Tenochtitlan se fundó en 1325 sobre un islote del lago de Texcoco y llegó a ser una de las ciudades más grandes del mundo de su época.",
                    @"Cleopatra vivió más cerca en el tiempo de la llegada del ser humano a la Luna (1969) que de la construcción de la Gran Pirámide de Guiza.",
                    @"El 16 de septiembre de 1810, con el Grito de Dolores, comenzó la Guerra de Independencia de México.",
                    @"La Constitución Política de los Estados Unidos Mexicanos vigente se promulgó en la ciudad de Querétaro el 5 de febrero de 1917.",
                    @"Hacia 1450, Johannes Gutenberg desarrolló en Europa la imprenta de tipos móviles, que transformó la forma de difundir el conocimiento.",
                    @"La Real y Pontificia Universidad de México, fundada en 1551, fue una de las primeras universidades de América.",
                    @"El Acueducto de Querétaro, construido en el siglo XVIII, mide aproximadamente 1 280 metros de largo y tiene 74 arcos.",
                    @"La Gran Muralla China no se construyó de una sola vez: fue levantada y ampliada por distintas dinastías a lo largo de muchos siglos."
                ]
            },
            @{
                kNameKey: @"Tecnología",
                kEmojiKey: @"💻",
                kFactsKey: @[
                    @"El primer correo electrónico en red lo envió Ray Tomlinson en 1971 y fue él quien eligió el símbolo @ para separar el usuario del equipo.",
                    @"El primer ratón de computadora fue diseñado por Douglas Engelbart en 1964 y tenía una carcasa de madera.",
                    @"Tim Berners-Lee puso en marcha el primer sitio web en el CERN; la web se abrió al público en 1991.",
                    @"Objective-C nació a inicios de los años 80 y fue el lenguaje principal para programar apps de iOS hasta que Apple presentó Swift en 2014.",
                    @"El primer iPhone se presentó el 9 de enero de 2007 y salió a la venta ese mismo año.",
                    @"La palabra «robot» proviene del término checo «robota» (trabajo forzado) y se popularizó con la obra de teatro R.U.R., de Karel Čapek, estrenada en 1921.",
                    @"El IBM 305 RAMAC, de 1956, fue el primer computador comercial con disco duro: almacenaba unos 5 millones de caracteres (alrededor de 4 MB) y su unidad de disco pesaba más de una tonelada.",
                    @"En 1947 se halló una polilla atrapada en un relé de la computadora Harvard Mark II; el hecho se documentó como un «bug» real y popularizó el término."
                ]
            }
        ];
    }
    return self;
}

#pragma mark - Consulta de categorías

- (NSInteger)categoryCount {
    return (NSInteger)self.categories.count;
}

- (NSArray<NSString *> *)categoryNames {
    return [self.categories valueForKey:kNameKey];
}

- (NSArray<NSString *> *)categoryEmojis {
    return [self.categories valueForKey:kEmojiKey];
}

- (NSInteger)factCountForCategoryIndex:(NSInteger)index {
    if (![self isValidIndex:index]) { return 0; }
    NSArray *facts = self.categories[(NSUInteger)index][kFactsKey];
    return (NSInteger)facts.count;
}

- (NSInteger)shownCountForCategoryIndex:(NSInteger)index {
    return self.cursors[@(index)].integerValue;
}

#pragma mark - Entrega de datos

- (NSString *)nextFactForCategoryIndex:(NSInteger)index {
    if (![self isValidIndex:index]) { return @""; }

    NSNumber *key = @(index);
    NSArray<NSString *> *facts = self.categories[(NSUInteger)index][kFactsKey];
    NSMutableArray<NSNumber *> *order = self.orders[key];
    NSInteger cursor = self.cursors[key].integerValue;

    // Si no hay orden o ya se mostraron todos los datos, se genera un nuevo recorrido.
    if (order == nil || cursor >= (NSInteger)order.count) {
        [self prepareOrderForCategoryIndex:index];
        order = self.orders[key];
        cursor = 0;
    }

    NSNumber *factIndex = order[(NSUInteger)cursor];
    self.cursors[key] = @(cursor + 1);
    self.lastFactIndexes[key] = factIndex;
    return facts[factIndex.unsignedIntegerValue];
}

- (void)resetCategoryIndex:(NSInteger)index {
    if (![self isValidIndex:index]) { return; }
    [self prepareOrderForCategoryIndex:index];
}

#pragma mark - Auxiliares

- (BOOL)isValidIndex:(NSInteger)index {
    return index >= 0 && index < (NSInteger)self.categories.count;
}

/// Crea un orden aleatorio (Fisher-Yates) para la categoría y reinicia su cursor.
/// Si el primer elemento coincide con el último dato mostrado, lo intercambia
/// para evitar que el mismo dato aparezca dos veces seguidas.
- (void)prepareOrderForCategoryIndex:(NSInteger)index {
    NSInteger count = [self factCountForCategoryIndex:index];
    NSMutableArray<NSNumber *> *order = [NSMutableArray arrayWithCapacity:(NSUInteger)count];
    for (NSInteger i = 0; i < count; i++) {
        [order addObject:@(i)];
    }
    for (NSInteger i = count - 1; i > 0; i--) {
        NSUInteger j = arc4random_uniform((uint32_t)(i + 1));
        [order exchangeObjectAtIndex:(NSUInteger)i withObjectAtIndex:j];
    }

    NSNumber *last = self.lastFactIndexes[@(index)];
    if (last != nil && count > 1 && [order.firstObject isEqualToNumber:last]) {
        [order exchangeObjectAtIndex:0 withObjectAtIndex:(NSUInteger)(count - 1)];
    }

    self.orders[@(index)] = order;
    self.cursors[@(index)] = @0;
}

@end
