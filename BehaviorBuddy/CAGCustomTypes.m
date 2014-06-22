#import "CAGCustomTypes.h"

@implementation CAGResponse

- (id)init
{
  return [super init];
}

- (id)initWithName:(NSString *)name
{
  self = [super init];
  if (self) {
    _name = name;
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
  [encoder encodeObject:self.name forKey:@"name"];
}

- (id)initWithCoder:(NSCoder *)decoder {
  self = [super init];
  if (self) {
    _name = [decoder decodeObjectForKey:@"name"];
  }
  return self;
}

@end


@interface CAGInitiation ()

@property (readwrite) NSMutableArray *responses;

@end

@implementation CAGInitiation

- (id)init
{
  self = [super init];
  if (self) {
    _color = [UIColor blackColor];
    _responses = [[NSMutableArray alloc] init];
  }
  return self;
}

- (id)initWithName:(NSString *)name
{
  self = [super init];
  if (self) {
    _name = name;
    _color = [UIColor blackColor];
    _responses = [[NSMutableArray alloc] init];
  }
  return self;
}

- (id)initWithName:(NSString *)name imageUrl:(NSURL *)imageUrl imageSize:(NSUInteger)imageSize color:(UIColor *)color responses:(NSMutableArray *)responses
{
  self = [super init];
  if (self) {
    _name = name;
    _imageUrl = imageUrl;
    _imageSize = imageSize;
    _color = color;
    _responses = responses;
  }
  return self;
}

- (void)addResponse:(CAGResponse *)response
{
  [self.responses addObject:response];
}

- (CAGResponse *)getResponseAtIndex:(NSUInteger)index
{
  return [self.responses objectAtIndex:index];
}

- (CAGResponse *)removeResponseAtIndex:(NSUInteger)index
{
  CAGResponse *removedResponse = [self.responses objectAtIndex:index];
  [self.responses removeObjectAtIndex:index];
  return removedResponse;
}

- (void)removeResponse:(CAGResponse *)response
{
  [self.responses removeObjectIdenticalTo:response];
}

- (void)encodeWithCoder:(NSCoder *)encoder {
  [encoder encodeObject:self.name forKey:@"name"];
  [encoder encodeObject:self.imageUrl forKey:@"imageUrl"];
  [encoder encodeObject:[NSNumber numberWithUnsignedInteger:self.imageSize] forKey:@"imageSize"];
  [encoder encodeObject:self.color forKey:@"color"];
  [encoder encodeObject:self.responses forKey:@"responses"];
}

- (id)initWithCoder:(NSCoder *)decoder {
  self = [super init];
  if (self) {
    _name = [decoder decodeObjectForKey:@"name"];
    _imageUrl = [decoder decodeObjectForKey:@"imageUrl"];
    _imageSize = [[decoder decodeObjectForKey:@"imageSize"] unsignedIntegerValue];
    _color = [decoder decodeObjectForKey:@"color"];
    _responses = [decoder decodeObjectForKey:@"responses"];
  }
  return self;
}

@end

@interface CAGSetting ()

@property (readwrite) NSMutableDictionary *initiationTypesRequired;
@property (readwrite) NSMutableDictionary *hiddenInitiations;
@property (readwrite) NSMutableDictionary *initiationTypesPerformed;
@property (readwrite) NSMutableArray *initiationsPerformed;

@end

@implementation CAGSetting

- (id)init
{
  self = [super init];
  if (self) {
    _initiationTypesRequired = [[NSMutableDictionary alloc] init];
    _hiddenInitiations = [[NSMutableDictionary alloc] init];
    _initiationTypesPerformed = [[NSMutableDictionary alloc] init];
    _initiationsPerformed = [[NSMutableArray alloc] init];
  }
  return self;
}

- (id)initWithName:(NSString *)name
{
  self = [super init];
  if (self) {
    _name = name;
    _initiationTypesRequired = [[NSMutableDictionary alloc] init];
    _hiddenInitiations = [[NSMutableDictionary alloc] init];
    _initiationTypesPerformed = [[NSMutableDictionary alloc] init];
    _initiationsPerformed = [[NSMutableArray alloc] init];
  }
  return self;
}

- (id)initWithName:(NSString *)name initiationsPerformed:(NSMutableArray *)initiationsPerformed initiationTypesRequired:(NSMutableDictionary *)initiationTypesRequired initiationTypesPerformed:(NSMutableDictionary *)initiationTypesPerformed
{
  self = [super init];
  if (self) {
    _name = name;
    _initiationTypesRequired = initiationTypesRequired;
    _hiddenInitiations = [[NSMutableDictionary alloc] init];
    _initiationTypesPerformed = initiationTypesPerformed;
    _initiationsPerformed = initiationsPerformed;
  }
  return self;
}

- (void)initiationPerformed:(CAGInitiation *)initiation initiationType:(CAGInitiationType *)initiationType
{
  [self.initiationsPerformed addObject:initiation];
  NSUInteger current = [[self.initiationTypesPerformed objectForKey:initiationType.name] integerValue];
  if (!current) {
    current = 1;
  }
  else {
    current++;
  }
  [self.initiationTypesPerformed setObject:[NSNumber numberWithInteger:current] forKey:initiationType.name];
}

- (CAGInitiation *)getInitiationPerformedAtIndex:(NSUInteger)index
{
  return [self.initiationsPerformed objectAtIndex:index];
}

- (void)setNumInitiationsRequired:(NSUInteger)numRequired initiationType:(CAGInitiationType *)initiationType
{
  [self.initiationTypesRequired setObject:[NSNumber numberWithInteger:numRequired] forKey:initiationType.name];
}

- (void)setAvailability:(BOOL)available forInitiationAtIndex:(NSUInteger)index initiationType:(CAGInitiationType *)initiationType
{
  if (available) {
    [self.hiddenInitiations removeObjectForKey:[NSString stringWithFormat:@"%@,%lu", initiationType.name, (unsigned long)index]];
  }
  else {
    [self.hiddenInitiations setObject:[NSNumber numberWithBool:YES] forKey:[NSString stringWithFormat:@"%@,%lu", initiationType.name, (unsigned long)index]];
  }
}

- (BOOL)getAvailabilityForInitiationAtIndex:(NSUInteger)index initiationType:(CAGInitiationType *)initiationType
{
  return ![self.hiddenInitiations objectForKey:[NSString stringWithFormat:@"%@,%lu", initiationType.name, (unsigned long)index]];
}

- (NSUInteger)getNumInitiationsRequiredForInitiationType:(CAGInitiationType *)initiationType
{
  return [[self.initiationTypesRequired objectForKey:initiationType.name] integerValue];
}

- (NSUInteger)getNumInitiationsPerformedForInitiationType:(CAGInitiationType *)initiationType
{
  return [[self.initiationTypesPerformed objectForKey:initiationType.name] integerValue];
}

- (float)getCompletionPercentageForInitiationType:(CAGInitiationType *)initiationType
{
  float numPerformed = (float) [self getNumInitiationsPerformedForInitiationType:initiationType];
  float numRequired = (float) [self getNumInitiationsRequiredForInitiationType:initiationType];
  if (numRequired == 0) {
    return 1;
  }
  return numPerformed / numRequired;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
  [encoder encodeObject:self.name forKey:@"name"];
  [encoder encodeObject:[NSNumber numberWithBool:self.finished] forKey:@"finished"];
  [encoder encodeObject:self.initiationTypesRequired forKey:@"initiationTypesRequired"];
  [encoder encodeObject:self.hiddenInitiations forKey:@"hiddenInitiations"];
  [encoder encodeObject:self.initiationTypesPerformed forKey:@"initiationTypesPerformed"];
  [encoder encodeObject:self.initiationsPerformed forKey:@"initiationsPerformed"];
}

- (id)initWithCoder:(NSCoder *)decoder
{
  self = [super init];
  if (self) {
    _name = [decoder decodeObjectForKey:@"name"];
    _finished = [[decoder decodeObjectForKey:@"finished"] boolValue];
    _initiationTypesRequired = [decoder decodeObjectForKey:@"initiationTypesRequired"];
    _hiddenInitiations = [decoder decodeObjectForKey:@"hiddenInitiations"];
    if (!_hiddenInitiations) {
      _hiddenInitiations = [[NSMutableDictionary alloc] init];
    }
    _initiationTypesPerformed = [decoder decodeObjectForKey:@"initiationTypesPerformed"];
    _initiationsPerformed = [decoder decodeObjectForKey:@"initiationsPerformed"];
  }
  return self;
}

@end

@interface CAGSession ()

@property (readwrite) NSMutableArray *settings;

@end

@implementation CAGSession

- (id)init
{
  self = [super init];
  if (self) {
    _settings = [[NSMutableArray alloc] init];
  }
  return self;
}

- (id)initWithName:(NSString *)name
{
  self = [super init];
  if (self) {
    _name = name;
    _settings = [[NSMutableArray alloc] init];
  }
  return self;
}

- (id)initWithName:(NSString *)name settings:(NSMutableArray *)settings
{
  self = [super init];
  if (self) {
    _name = name;
    _settings = settings;
  }
  return self;
}

- (void)addSetting:(CAGSetting *)setting
{
  [self.settings addObject:setting];
}

- (CAGSetting *)getSettingAtIndex:(NSUInteger)index
{
  return [self.settings objectAtIndex:index];
}

- (CAGSetting *)removeSettingAtIndex:(NSUInteger)index
{
  CAGSetting *removedSetting = [self.settings objectAtIndex:index];
  [self.settings removeObjectAtIndex:index];
  return  removedSetting;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
  [encoder encodeObject:self.name forKey:@"name"];
  [encoder encodeObject:self.settings forKey:@"settings"];
}

- (id)initWithCoder:(NSCoder *)decoder
{
  self = [super init];
  if (self) {
    _name = [decoder decodeObjectForKey:@"name"];
    _settings = [decoder decodeObjectForKey:@"settings"];
  }
  return self;
}

@end

@interface CAGInitiationType ()

@property (readwrite) NSMutableArray *initiations;

@end

@implementation CAGInitiationType

- (id)init
{
  self = [super init];
  if (self) {
    _initiations = [[NSMutableArray alloc] init];
  }
  return self;
}

- (id)initWithName:(NSString *)name
{
  self = [super init];
  if (self) {
    _name = name;
    _color = [UIColor blackColor];
    _initiations = [[NSMutableArray alloc] init];
  }
  return self;
}

- (id)initWithName:(NSString *)name description:(NSString *)description
{
  self = [super init];
  if (self) {
    _name = name;
    _color = [UIColor blackColor];
    _description = description;
    _initiations = [[NSMutableArray alloc] init];
  }
  return self;
}

- (id)initWithName:(NSString *)name color:(UIColor *)color description:(NSString *)description initiations:(NSMutableArray *)initiations
{
  self = [super init];
  if (self) {
    _name = name;
    _color = color;
    _description = description;
    _initiations = initiations;
  }
  return self;
}

- (void)addInitiation:(CAGInitiation *)initiation
{
  [self.initiations addObject:initiation];
}

- (CAGInitiation *)getInitiationAtIndex:(NSUInteger)index
{
  return [self.initiations objectAtIndex:index];
}

- (CAGInitiation *)removeInitiationAtIndex:(NSUInteger)index
{
  CAGInitiation *removedInitiation = [self.initiations objectAtIndex:index];
  [self.initiations removeObjectAtIndex:index];
  return removedInitiation;
}

- (void)removeInitiationLike:(CAGInitiation *)initiation
{
  [self.initiations removeObjectIdenticalTo:initiation];
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
  [encoder encodeObject:self.name forKey:@"name"];
  [encoder encodeObject:self.color forKey:@"color"];
  [encoder encodeObject:self.initiations forKey:@"initiations"];
}

- (id)initWithCoder:(NSCoder *)decoder
{
  self = [super init];
  if (self) {
    _name = [decoder decodeObjectForKey:@"name"];
    _color = [decoder decodeObjectForKey:@"color"];
    if (!_color) {
      _color = [UIColor blackColor];
    }
    _initiations = [decoder decodeObjectForKey:@"initiations"];
  }
  return self;
}

@end


@interface CAGParticipant ()

@property (readwrite) NSMutableArray *initiationTypes;
@property (readwrite) NSMutableArray *sessions;

@end

@implementation CAGParticipant

- (id)init
{
  self = [super init];
  if (self) {
    _initiationTypes = [[NSMutableArray alloc] init];
    _sessions = [[NSMutableArray alloc] init];
  }
  return self;
}

- (id)initWithName:(NSString *)name
{
  self = [super init];
  if (self) {
    _name = name;
    _initiationTypes = [[NSMutableArray alloc] init];
    _sessions = [[NSMutableArray alloc] init];
  }
  return self;
}

- (id)initWithName:(NSString *)name initiationTypes:(NSMutableArray *)initiationTypes sessions:(NSMutableArray *)sessions
{
  self = [super init];
  if (self) {
    _name = name;
    _initiationTypes = initiationTypes;
    _sessions = sessions;
  }
  return self;
}

- (void)addInitiationType:(CAGInitiationType *)initiationType
{
  [self.initiationTypes addObject:initiationType];
}

- (CAGInitiationType *)getInitiationTypeAtIndex:(NSUInteger)index
{
  return [self.initiationTypes objectAtIndex:index];
}

- (CAGInitiationType *)removeInitiationTypeAtIndex:(NSUInteger)index
{
  CAGInitiationType *removedInitiationType = [self.initiationTypes objectAtIndex:index];
  [self.initiationTypes removeObjectAtIndex:index];
  return removedInitiationType;
}

- (void)removeInitiationType:(CAGInitiationType *)initiationType
{
  [self.initiationTypes removeObjectIdenticalTo:initiationType];
}

- (void)addSession:(CAGSession *)session
{
  [self.sessions addObject:session];
}

- (CAGSession *)getSessionAtIndex:(NSUInteger)index
{
  return [self.sessions objectAtIndex:index];
}

- (CAGSession *)removeSessionAtIndex:(NSUInteger)index
{
  CAGSession *removedSession = [self.sessions objectAtIndex:index];
  [self.sessions removeObjectAtIndex:index];
  return removedSession;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
  [encoder encodeObject:self.name forKey:@"name"];
  [encoder encodeObject:self.initiationTypes forKey:@"initiationTypes"];
  [encoder encodeObject:self.sessions forKey:@"sessions"];
}

- (id)initWithCoder:(NSCoder *)decoder
{
  self = [super init];
  if (self) {
    _name = [decoder decodeObjectForKey:@"name"];
    _initiationTypes = [decoder decodeObjectForKey:@"initiationTypes"];
    _sessions = [decoder decodeObjectForKey:@"sessions"];
  }
  return self;
}

@end

@implementation UIImagePickerController(Nonrotating)

- (BOOL)shouldAutorotate {
  return NO;
}

@end
