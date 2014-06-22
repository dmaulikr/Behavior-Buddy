#import <Foundation/Foundation.h>

@interface CAGResponse : NSObject <NSCoding>

@property NSString *name;

- (id)init;
- (id)initWithName:(NSString *)name;

@end

@interface CAGInitiation : NSObject <NSCoding>

@property NSString *name;
@property NSURL *imageUrl;
@property NSUInteger imageSize;
@property UIColor *color;
@property (readonly) NSMutableArray *responses;

- (id)init;
- (id)initWithName:(NSString *)name;
- (id)initWithName:(NSString *)name imageUrl:(NSURL *)imageUrl imageSize:(NSUInteger)imageSize color:(UIColor *)color responses:(NSMutableArray *)responses;
- (void)addResponse:(CAGResponse *)response;
- (CAGResponse *)getResponseAtIndex:(NSUInteger)index;
- (CAGResponse *)removeResponseAtIndex:(NSUInteger)index;
- (void)removeResponse:(CAGResponse *)response;

@end

@interface CAGInitiationType : NSObject <NSCoding>

@property NSString *name;
@property UIColor *color;
@property NSString *description;
@property (readonly) NSMutableArray *initiations;

- (id)init;
- (id)initWithName:(NSString *)name;
- (id)initWithName:(NSString *)name description:(NSString *)description;
- (id)initWithName:(NSString *)name color:(UIColor *)color description:(NSString *)description initiations:(NSMutableArray *)initiations;
- (void)addInitiation:(CAGInitiation *)initiation;
- (CAGInitiation *)getInitiationAtIndex:(NSUInteger)index;
- (CAGInitiation *)removeInitiationAtIndex:(NSUInteger)index;
- (void)removeInitiationLike:(CAGInitiation *)initiation;

@end

@interface CAGSetting : NSObject <NSCoding>

@property NSString *name;
@property BOOL finished;
@property (readonly) NSMutableDictionary *initiationTypesRequired;
@property (readonly) NSMutableDictionary *hiddenInitiations;
@property (readonly) NSMutableDictionary *initiationTypesPerformed;
@property (readonly) NSMutableArray *initiationsPerformed;

- (id)init;
- (id)initWithName:(NSString *)name;
- (id)initWithName:(NSString *)name initiationsPerformed:(NSMutableArray *)initiationsPerformed initiationTypesRequired:(NSMutableDictionary *)initiationTypesRequired initiationTypesPerformed:(NSMutableDictionary *)initiationTypesPerformed;
- (void)initiationPerformed:(CAGInitiation *)initiation initiationType:(CAGInitiationType *)initiationType;
- (CAGInitiation *)getInitiationPerformedAtIndex:(NSUInteger)index;
- (void)setNumInitiationsRequired:(NSUInteger)numRequired initiationType:(CAGInitiationType *)initiationType;
- (void)setAvailability:(BOOL)available forInitiationAtIndex:(NSUInteger)index initiationType:(CAGInitiationType *)initiationType;
- (BOOL)getAvailabilityForInitiationAtIndex:(NSUInteger)index initiationType:(CAGInitiationType *)initiationType;
- (NSUInteger)getNumInitiationsRequiredForInitiationType:(CAGInitiationType *)initiationType;
- (NSUInteger)getNumInitiationsPerformedForInitiationType:(CAGInitiationType *)initiationType;
- (float)getCompletionPercentageForInitiationType:(CAGInitiationType *)initiationType;

@end

@interface CAGSession : NSObject <NSCoding>

@property NSString *name;
@property (readonly) NSMutableArray *settings;

- (id)init;
- (id)initWithName:(NSString *)name;
- (id)initWithName:(NSString *)name settings:(NSMutableArray *)settings;
- (void)addSetting:(CAGSetting *)setting;
- (CAGSetting *)getSettingAtIndex:(NSUInteger)index;
- (CAGSetting *)removeSettingAtIndex:(NSUInteger)index;

@end

@interface CAGParticipant : NSObject <NSCoding>

@property NSString *name;
@property (readonly) NSMutableArray *initiationTypes;
@property (readonly) NSMutableArray *sessions;

- (id)init;
- (id)initWithName:(NSString *)name;
- (id)initWithName:(NSString *)name initiationTypes:(NSMutableArray *)initiationTypes sessions:(NSMutableArray *)sessions;
- (void)addInitiationType:(CAGInitiationType *)initiationType;
- (CAGInitiationType *)getInitiationTypeAtIndex:(NSUInteger)index;
- (CAGInitiationType *)removeInitiationTypeAtIndex:(NSUInteger)index;
- (void)removeInitiationType:(CAGInitiationType *)initiationType;
- (void)addSession:(CAGSession *)session;
- (CAGSession *)getSessionAtIndex:(NSUInteger)index;
- (CAGSession *)removeSessionAtIndex:(NSUInteger)index;

@end

@interface UIImagePickerController(Nonrotating)
- (BOOL)shouldAutorotate;
@end
