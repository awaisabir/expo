// Copyright 2015-present 650 Industries. All rights reserved.

#import <EXSpeechModule/EXSpeech.h>
#import <AVFoundation/AVFoundation.h>
#import <EXCore/EXEventEmitterService.h>

@interface EXSpeechUtteranceWithId : AVSpeechUtterance

@property (nonatomic) NSString* utteranceId;

- (instancetype)initWithString:(NSString *)string utteranceId:(NSString *)utteranceId;

@end

@implementation EXSpeechUtteranceWithId

- (instancetype)initWithString:(NSString *)string utteranceId:(NSString *)utteranceId
{
  self = [super initWithString:string];
  if (self) {
    _utteranceId = utteranceId;
  }
  return self;
}

@end

@interface EXSpeech () <AVSpeechSynthesizerDelegate>

@property (nonatomic, strong) AVSpeechSynthesizer *synthesizer;
@property (nonatomic, weak) EXModuleRegistry *moduleRegistry;

@end

@implementation EXSpeech

EX_EXPORT_MODULE(ExponentSpeech)

- (void)setModuleRegistry:(EXModuleRegistry *)moduleRegistry
{
  _moduleRegistry = moduleRegistry;
}

- (NSArray<NSString *> *)supportedEvents
{
  return @[@"Exponent.speakingStarted", @"Exponent.speakingDone", @"Exponent.speakingStopped", @"Exponent.speakingError"];
}

- (void)startObserving {
}


- (void)stopObserving {
}


- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer
  didStartSpeechUtterance:(AVSpeechUtterance *)utterance
{
  id<EXEventEmitterService> emiter = [_moduleRegistry getModuleImplementingProtocol:@protocol(EXEventEmitterService)];
  if (emiter != nil) {
    [emiter sendEventWithName:@"Exponent.speakingStarted" body:@{ @"id": ((EXSpeechUtteranceWithId *) utterance).utteranceId }];
  }
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer
 didCancelSpeechUtterance:(AVSpeechUtterance *)utterance
{
  id<EXEventEmitterService> emiter = [_moduleRegistry getModuleImplementingProtocol:@protocol(EXEventEmitterService)];
  if (emiter != nil) {
    [emiter sendEventWithName:@"Exponent.speakingStopped" body:@{ @"id": ((EXSpeechUtteranceWithId *) utterance).utteranceId }];
  }
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer
 didFinishSpeechUtterance:(AVSpeechUtterance *)utterance
{
  id<EXEventEmitterService> emiter = [_moduleRegistry getModuleImplementingProtocol:@protocol(EXEventEmitterService)];
  if (emiter != nil) {
    [emiter sendEventWithName:@"Exponent.speakingDone" body:@{ @"id": ((EXSpeechUtteranceWithId *) utterance).utteranceId }];
  }
}


EX_EXPORT_METHOD_AS(speak,
                    speak:(nonnull NSString *)utteranceId
                    text:(nonnull NSString *)text
                    options:(NSDictionary *)options
                    resolver:(EXPromiseResolveBlock)resolve
                    rejecter:(EXPromiseRejectBlock)reject) {
  if (_synthesizer == nil) {
    _synthesizer = [[AVSpeechSynthesizer alloc] init];
    _synthesizer.delegate = self;
  }

  AVSpeechUtterance *utterance = [[EXSpeechUtteranceWithId alloc] initWithString:text utteranceId:utteranceId];

  NSString *language = options[@"language"];
  NSString *voice = options[@"voiceIOS"];
  NSNumber *pitch = options[@"pitch"];
  NSNumber *rate = options[@"rate"];

  if (language != nil) {
    utterance.voice = [AVSpeechSynthesisVoice voiceWithLanguage:language];
  }
  if (voice != nil) {
    utterance.voice = [AVSpeechSynthesisVoice voiceWithIdentifier:voice];
  }
  if (pitch != nil) {
    utterance.pitchMultiplier = [pitch floatValue];
  }
  if (rate != nil) {
    utterance.rate = [rate floatValue] * AVSpeechUtteranceDefaultSpeechRate;
  }

  [_synthesizer speakUtterance:utterance];
  resolve(nil);
}

EX_EXPORT_METHOD_AS(stop,
                    stop:(EXPromiseResolveBlock)resolve
                    rejecter:(EXPromiseRejectBlock)reject) {
  [_synthesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
  resolve(nil);
}

EX_EXPORT_METHOD_AS(pause,
                    pause:(EXPromiseResolveBlock)resolve
                    rejecter:(EXPromiseRejectBlock)reject) {
  [_synthesizer pauseSpeakingAtBoundary:AVSpeechBoundaryImmediate];
  resolve(nil);
}

EX_EXPORT_METHOD_AS(resume,
                    resume:(EXPromiseResolveBlock)resolve
                    rejecter:(EXPromiseRejectBlock)reject) {
  [_synthesizer continueSpeaking];
  resolve(nil);
}

EX_EXPORT_METHOD_AS(isSpeaking,
                    isSpeaking:(EXPromiseResolveBlock)resolve
                    rejecter:(EXPromiseRejectBlock)reject) {
  resolve(@([_synthesizer isSpeaking]));
}

+ (const NSArray<Protocol *> *)exportedInterfaces {
  return @[];
}


@end
  
