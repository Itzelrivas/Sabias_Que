//
//  ViewController.m
//  SabiasQue
//
//  Pantalla única de la app «¿Sabías qué?».
//
//  Funcionamiento:
//   1. El usuario elige una de tres categorías (UISegmentedControl).
//   2. Al tocar el botón se muestra un dato curioso de esa categoría.
//   3. Al tocar nuevamente el botón se muestra información diferente de la misma categoría.
//
//  La interfaz se construye por código (Auto Layout) y respeta el modo oscuro
//  y el tamaño de letra dinámico (Dynamic Type).
//

#import "ViewController.h"
#import "FactsStore.h"

/// Estados posibles de la pantalla.
typedef NS_ENUM(NSInteger, SQScreenState) {
    SQScreenStateNoCategory,        // Aún no se elige categoría
    SQScreenStateCategorySelected,  // Categoría elegida, todavía sin dato
    SQScreenStateFactShown          // Se está mostrando un dato curioso
};

@interface ViewController ()

@property (nonatomic, strong) FactsStore *store;
@property (nonatomic, assign) SQScreenState state;
@property (nonatomic, strong) UIColor *currentAccent;

// Vistas
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subtitleLabel;
@property (nonatomic, strong) UILabel *chooseLabel;
@property (nonatomic, strong) UISegmentedControl *categoryControl;
@property (nonatomic, strong) UIView *cardView;
@property (nonatomic, strong) UILabel *tagLabel;
@property (nonatomic, strong) UILabel *counterLabel;
@property (nonatomic, strong) UILabel *iconLabel;
@property (nonatomic, strong) UILabel *factLabel;
@property (nonatomic, strong) UIButton *factButton;

@end

@implementation ViewController

#pragma mark - Ciclo de vida

- (void)viewDidLoad {
    [super viewDidLoad];

    self.store = [[FactsStore alloc] init];
    self.view.backgroundColor = [UIColor systemBackgroundColor];

    [self buildInterface];
    [self applyState:SQScreenStateNoCategory fact:nil animated:NO];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    // Los CGColor no se adaptan solos al modo claro/oscuro: se vuelven a resolver.
    [self refreshBorderColor];
}

#pragma mark - Construcción de la interfaz

- (void)buildInterface {
    // Contenedor central (limita el ancho en iPad).
    self.contentView = [[UIView alloc] init];
    self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.contentView];

    UIFont *titleFont = [[UIFontMetrics metricsForTextStyle:UIFontTextStyleLargeTitle]
                         scaledFontForFont:[UIFont systemFontOfSize:34 weight:UIFontWeightHeavy]];

    self.titleLabel = [self labelWithFont:titleFont
                                    color:[UIColor labelColor]
                                alignment:NSTextAlignmentCenter];
    self.titleLabel.text = @"¿Sabías qué?";
    self.titleLabel.accessibilityTraits = UIAccessibilityTraitHeader;

    self.subtitleLabel = [self labelWithFont:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]
                                       color:[UIColor secondaryLabelColor]
                                   alignment:NSTextAlignmentCenter];
    self.subtitleLabel.text = @"Descubre datos curiosos con un solo toque";

    self.chooseLabel = [self labelWithFont:[UIFont preferredFontForTextStyle:UIFontTextStyleHeadline]
                                     color:[UIColor labelColor]
                                 alignment:NSTextAlignmentNatural];
    self.chooseLabel.text = @"Elige una categoría:";

    // Selector de categoría (3 opciones).
    self.categoryControl = [[UISegmentedControl alloc] initWithItems:self.store.categoryNames];
    self.categoryControl.translatesAutoresizingMaskIntoConstraints = NO;
    self.categoryControl.selectedSegmentIndex = UISegmentedControlNoSegment;
    [self.categoryControl setTitleTextAttributes:@{ NSForegroundColorAttributeName: [UIColor whiteColor] }
                                        forState:UIControlStateSelected];
    [self.categoryControl addTarget:self
                             action:@selector(categoryChanged:)
                   forControlEvents:UIControlEventValueChanged];
    self.categoryControl.accessibilityLabel = @"Categoría";

    // Tarjeta donde se muestra el dato.
    self.cardView = [[UIView alloc] init];
    self.cardView.translatesAutoresizingMaskIntoConstraints = NO;
    self.cardView.layer.cornerRadius = 24.0;
    self.cardView.layer.borderWidth = 1.5;

    self.tagLabel = [self labelWithFont:[UIFont preferredFontForTextStyle:UIFontTextStyleCaption1]
                                  color:[UIColor secondaryLabelColor]
                              alignment:NSTextAlignmentNatural];
    self.tagLabel.numberOfLines = 1;

    self.counterLabel = [self labelWithFont:[UIFont preferredFontForTextStyle:UIFontTextStyleCaption1]
                                      color:[UIColor secondaryLabelColor]
                                  alignment:NSTextAlignmentRight];
    self.counterLabel.numberOfLines = 1;

    self.iconLabel = [self labelWithFont:[UIFont systemFontOfSize:56] color:[UIColor labelColor]
                               alignment:NSTextAlignmentCenter];
    self.iconLabel.adjustsFontForContentSizeCategory = NO;
    self.iconLabel.isAccessibilityElement = NO;

    self.factLabel = [self labelWithFont:[UIFont preferredFontForTextStyle:UIFontTextStyleTitle3]
                                   color:[UIColor labelColor]
                               alignment:NSTextAlignmentCenter];

    UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[ self.iconLabel, self.factLabel ]];
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 16.0;

    [self.cardView addSubview:self.tagLabel];
    [self.cardView addSubview:self.counterLabel];
    [self.cardView addSubview:stack];

    // Botón principal.
    self.factButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.factButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.factButton.layer.cornerRadius = 16.0;
    self.factButton.titleLabel.font = [UIFont systemFontOfSize:19 weight:UIFontWeightSemibold];
    [self.factButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.factButton setTitleColor:[UIColor secondaryLabelColor] forState:UIControlStateDisabled];
    [self.factButton addTarget:self action:@selector(factButtonTapped)
              forControlEvents:UIControlEventTouchUpInside];
    [self.factButton addTarget:self action:@selector(buttonTouchDown)
              forControlEvents:UIControlEventTouchDown];
    [self.factButton addTarget:self action:@selector(buttonTouchUp)
              forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside |
                               UIControlEventTouchCancel | UIControlEventTouchDragExit];

    [self.contentView addSubview:self.titleLabel];
    [self.contentView addSubview:self.subtitleLabel];
    [self.contentView addSubview:self.chooseLabel];
    [self.contentView addSubview:self.categoryControl];
    [self.contentView addSubview:self.cardView];
    [self.contentView addSubview:self.factButton];

    [self activateConstraintsWithCardStack:stack];
}

- (void)activateConstraintsWithCardStack:(UIStackView *)stack {
    UILayoutGuide *safe = self.view.safeAreaLayoutGuide;

    // Contenedor: centrado, con ancho máximo y márgenes laterales de 24 pt.
    NSLayoutConstraint *leading = [self.contentView.leadingAnchor constraintEqualToAnchor:safe.leadingAnchor
                                                                                  constant:24];
    NSLayoutConstraint *trailing = [self.contentView.trailingAnchor constraintEqualToAnchor:safe.trailingAnchor
                                                                                    constant:-24];
    leading.priority = UILayoutPriorityDefaultHigh;
    trailing.priority = UILayoutPriorityDefaultHigh;

    [NSLayoutConstraint activateConstraints:@[
        [self.contentView.centerXAnchor constraintEqualToAnchor:safe.centerXAnchor],
        [self.contentView.widthAnchor constraintLessThanOrEqualToConstant:560],
        [self.contentView.topAnchor constraintEqualToAnchor:safe.topAnchor],
        [self.contentView.bottomAnchor constraintEqualToAnchor:safe.bottomAnchor],
        leading, trailing
    ]];

    // El centrado vertical del texto es "preferido": si hay poco espacio (iPhone pequeño con letra
    // muy grande) cede ante los límites superior e inferior de la tarjeta.
    NSLayoutConstraint *stackCenterY = [stack.centerYAnchor constraintEqualToAnchor:self.cardView.centerYAnchor
                                                                           constant:10];
    stackCenterY.priority = UILayoutPriorityDefaultHigh;

    UIView *c = self.contentView;
    [NSLayoutConstraint activateConstraints:@[
        // Encabezado
        [self.titleLabel.topAnchor constraintEqualToAnchor:c.topAnchor constant:28],
        [self.titleLabel.leadingAnchor constraintEqualToAnchor:c.leadingAnchor],
        [self.titleLabel.trailingAnchor constraintEqualToAnchor:c.trailingAnchor],

        [self.subtitleLabel.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:6],
        [self.subtitleLabel.leadingAnchor constraintEqualToAnchor:c.leadingAnchor],
        [self.subtitleLabel.trailingAnchor constraintEqualToAnchor:c.trailingAnchor],

        // Selector de categoría
        [self.chooseLabel.topAnchor constraintEqualToAnchor:self.subtitleLabel.bottomAnchor constant:32],
        [self.chooseLabel.leadingAnchor constraintEqualToAnchor:c.leadingAnchor],
        [self.chooseLabel.trailingAnchor constraintEqualToAnchor:c.trailingAnchor],

        [self.categoryControl.topAnchor constraintEqualToAnchor:self.chooseLabel.bottomAnchor constant:10],
        [self.categoryControl.leadingAnchor constraintEqualToAnchor:c.leadingAnchor],
        [self.categoryControl.trailingAnchor constraintEqualToAnchor:c.trailingAnchor],
        [self.categoryControl.heightAnchor constraintEqualToConstant:44],

        // Botón (anclado abajo)
        [self.factButton.leadingAnchor constraintEqualToAnchor:c.leadingAnchor],
        [self.factButton.trailingAnchor constraintEqualToAnchor:c.trailingAnchor],
        [self.factButton.bottomAnchor constraintEqualToAnchor:c.bottomAnchor constant:-24],
        [self.factButton.heightAnchor constraintEqualToConstant:56],

        // Tarjeta (ocupa el espacio disponible entre el selector y el botón)
        [self.cardView.topAnchor constraintEqualToAnchor:self.categoryControl.bottomAnchor constant:24],
        [self.cardView.leadingAnchor constraintEqualToAnchor:c.leadingAnchor],
        [self.cardView.trailingAnchor constraintEqualToAnchor:c.trailingAnchor],
        [self.cardView.bottomAnchor constraintEqualToAnchor:self.factButton.topAnchor constant:-24],

        // Contenido de la tarjeta
        [self.tagLabel.topAnchor constraintEqualToAnchor:self.cardView.topAnchor constant:16],
        [self.tagLabel.leadingAnchor constraintEqualToAnchor:self.cardView.leadingAnchor constant:20],

        [self.counterLabel.centerYAnchor constraintEqualToAnchor:self.tagLabel.centerYAnchor],
        [self.counterLabel.trailingAnchor constraintEqualToAnchor:self.cardView.trailingAnchor constant:-20],
        [self.counterLabel.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.tagLabel.trailingAnchor
                                                                      constant:8],

        stackCenterY,
        [stack.leadingAnchor constraintEqualToAnchor:self.cardView.leadingAnchor constant:20],
        [stack.trailingAnchor constraintEqualToAnchor:self.cardView.trailingAnchor constant:-20],
        [stack.topAnchor constraintGreaterThanOrEqualToAnchor:self.tagLabel.bottomAnchor constant:8],
        [stack.bottomAnchor constraintLessThanOrEqualToAnchor:self.cardView.bottomAnchor constant:-16]
    ]];

    // Evita que la etiqueta de categoría se comprima frente al contador.
    [self.tagLabel setContentCompressionResistancePriority:UILayoutPriorityRequired
                                                   forAxis:UILayoutConstraintAxisHorizontal];
}

- (UILabel *)labelWithFont:(UIFont *)font color:(UIColor *)color alignment:(NSTextAlignment)alignment {
    UILabel *label = [[UILabel alloc] init];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.font = font;
    label.textColor = color;
    label.textAlignment = alignment;
    label.numberOfLines = 0;
    label.adjustsFontForContentSizeCategory = YES;
    return label;
}

#pragma mark - Acciones

/// El usuario eligió (o cambió) la categoría.
- (void)categoryChanged:(UISegmentedControl *)sender {
    NSInteger index = sender.selectedSegmentIndex;
    if (index == UISegmentedControlNoSegment) { return; }

    [self.store resetCategoryIndex:index];

    UISelectionFeedbackGenerator *haptic = [[UISelectionFeedbackGenerator alloc] init];
    [haptic selectionChanged];

    [self applyState:SQScreenStateCategorySelected fact:nil animated:YES];
}

/// El usuario tocó el botón: se muestra un dato (distinto del anterior) de la categoría activa.
- (void)factButtonTapped {
    NSInteger index = self.categoryControl.selectedSegmentIndex;
    if (index == UISegmentedControlNoSegment) { return; }

    NSString *fact = [self.store nextFactForCategoryIndex:index];

    UIImpactFeedbackGenerator *haptic = [[UIImpactFeedbackGenerator alloc]
                                         initWithStyle:UIImpactFeedbackStyleLight];
    [haptic impactOccurred];

    [self applyState:SQScreenStateFactShown fact:fact animated:YES];
    UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, self.factLabel);
}

- (void)buttonTouchDown {
    self.factButton.alpha = 0.7;
}

- (void)buttonTouchUp {
    [UIView animateWithDuration:0.15 animations:^{
        self.factButton.alpha = 1.0;
    }];
}

#pragma mark - Estado de la pantalla

/// Actualiza textos, colores y estado del botón según el estado de la pantalla.
- (void)applyState:(SQScreenState)state fact:(NSString *)fact animated:(BOOL)animated {
    self.state = state;

    NSInteger index = self.categoryControl.selectedSegmentIndex;
    BOOL hasCategory = (index != UISegmentedControlNoSegment);
    UIColor *accent = hasCategory ? [self accentColorForIndex:index] : [UIColor systemGrayColor];
    self.currentAccent = accent;

    NSString *emoji = hasCategory ? self.store.categoryEmojis[(NSUInteger)index] : @"🤔";
    NSString *name = hasCategory ? self.store.categoryNames[(NSUInteger)index] : @"";

    void (^cardUpdates)(void) = ^{
        switch (state) {
            case SQScreenStateNoCategory:
                self.tagLabel.text = @"";
                self.counterLabel.text = @"";
                self.iconLabel.text = emoji;
                self.factLabel.text = @"Selecciona una categoría para comenzar";
                self.factLabel.textColor = [UIColor secondaryLabelColor];
                break;

            case SQScreenStateCategorySelected:
                self.tagLabel.text = [name uppercaseString];
                self.counterLabel.text = @"";
                self.iconLabel.text = emoji;
                self.factLabel.text = @"Toca el botón para descubrir un dato curioso";
                self.factLabel.textColor = [UIColor secondaryLabelColor];
                break;

            case SQScreenStateFactShown:
                self.tagLabel.text = [name uppercaseString];
                self.counterLabel.text = [NSString stringWithFormat:@"Dato %ld de %ld",
                                          (long)[self.store shownCountForCategoryIndex:index],
                                          (long)[self.store factCountForCategoryIndex:index]];
                self.iconLabel.text = emoji;
                self.factLabel.text = fact;
                self.factLabel.textColor = [UIColor labelColor];
                break;
        }
        self.tagLabel.textColor = hasCategory ? accent : [UIColor secondaryLabelColor];
        self.cardView.backgroundColor = hasCategory ? [accent colorWithAlphaComponent:0.12]
                                                    : [UIColor secondarySystemBackgroundColor];
        [self refreshBorderColor];
    };

    void (^controlUpdates)(void) = ^{
        BOOL enabled = hasCategory;
        self.factButton.enabled = enabled;
        self.factButton.backgroundColor = enabled ? accent : [UIColor systemGray5Color];
        if (hasCategory) {
            self.categoryControl.selectedSegmentTintColor = accent;
        }
    };

    NSString *buttonTitle = (state == SQScreenStateFactShown) ? @"Otro dato curioso" : @"Mostrar dato curioso";
    [self.factButton setTitle:buttonTitle forState:UIControlStateNormal];
    [self.factButton setTitle:buttonTitle forState:UIControlStateDisabled];
    self.factButton.accessibilityHint = hasCategory
        ? @"Muestra un dato curioso de la categoría seleccionada"
        : @"Primero selecciona una categoría";

    if (animated) {
        [UIView transitionWithView:self.cardView
                          duration:0.25
                           options:UIViewAnimationOptionTransitionCrossDissolve |
                                   UIViewAnimationOptionAllowUserInteraction
                        animations:cardUpdates
                        completion:nil];
        [UIView animateWithDuration:0.25 animations:controlUpdates];
    } else {
        cardUpdates();
        controlUpdates();
    }
}

/// Color de la categoría (se usa en el botón, el selector y la tarjeta).
- (UIColor *)accentColorForIndex:(NSInteger)index {
    switch (index) {
        case 0:  return [UIColor systemBlueColor];    // Ciencia
        case 1:  return [UIColor systemBrownColor];   // Historia
        default: return [UIColor systemPurpleColor];  // Tecnología
    }
}

/// Vuelve a calcular el color del borde (CGColor) con el modo claro/oscuro actual.
- (void)refreshBorderColor {
    UIColor *base = (self.state == SQScreenStateNoCategory) ? [UIColor separatorColor] : self.currentAccent;
    if (base == nil) { return; }
    self.cardView.layer.borderColor = [base resolvedColorWithTraitCollection:self.traitCollection].CGColor;
}

@end
