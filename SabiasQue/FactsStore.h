//
//  FactsStore.h
//  SabiasQue
//
//  Modelo de datos de la app «¿Sabías qué?».
//  Contiene las categorías y sus datos curiosos, y se encarga de entregar
//  un dato distinto cada vez que se solicita uno.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FactsStore : NSObject

/// Nombres de las categorías disponibles (en el orden en que se muestran).
@property (nonatomic, readonly) NSArray<NSString *> *categoryNames;

/// Emoji representativo de cada categoría (mismo orden que `categoryNames`).
@property (nonatomic, readonly) NSArray<NSString *> *categoryEmojis;

/// Total de categorías.
@property (nonatomic, readonly) NSInteger categoryCount;

/// Regresa el siguiente dato curioso de la categoría indicada.
/// Los datos se recorren en orden aleatorio sin repetirse hasta agotar la lista;
/// al reiniciar el ciclo nunca se repite el último dato mostrado de forma consecutiva.
- (NSString *)nextFactForCategoryIndex:(NSInteger)index;

/// Reinicia el recorrido de una categoría (se usa al cambiar de categoría).
- (void)resetCategoryIndex:(NSInteger)index;

/// Cantidad total de datos que tiene la categoría.
- (NSInteger)factCountForCategoryIndex:(NSInteger)index;

/// Cantidad de datos que ya se han mostrado en el recorrido actual de la categoría.
- (NSInteger)shownCountForCategoryIndex:(NSInteger)index;

@end

NS_ASSUME_NONNULL_END
