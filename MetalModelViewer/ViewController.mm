//
//  ViewController.mm
//  MetalModelViewer
//
//  Created by Jinwoo Kim on 9/4/24.
//

#import "ViewController.h"
#import "ModelView.h"
#include <ranges>
#include <span>
#include <vector>
#import <objc/message.h>
#import <objc/runtime.h>

@interface ViewController ()
@end

@implementation ViewController

- (void)loadView {
    ModelView *modelView = [ModelView new];
    self.view = modelView;
    [modelView release];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UINavigationItem *navigationItem = self.navigationItem;
    
    UIBarButtonItem *modelBarButtonItem = [UIBarButtonItem new];
    
    __weak auto weakSelf = self;
    modelBarButtonItem.menu = [UIMenu menuWithChildren:@[
        [UIDeferredMenuElement elementWithUncachedProvider:^(void (^ _Nonnull completion)(NSArray<UIMenuElement *> * _Nonnull)) {
        completion([weakSelf modelSelectionActions]);
    }]
    ]];
    
    modelBarButtonItem.title = NSStringFromModelType(static_cast<ModelView *>(self.view).modelType);
    
    navigationItem.rightBarButtonItem = modelBarButtonItem;
    [modelBarButtonItem release];
}

- (NSArray<UIAction *> *)modelSelectionActions {
    auto modelView = static_cast<ModelView *>(self.view);
    NSUInteger count;
    ModelType *modelTypes = allModelTypes(&count);
    ModelType selectedModelType = modelView.modelType;
    __weak auto weakSelf = self;
    
    auto childrenVec = std::span<ModelType>(modelTypes, count)
    | std::views::filter([](ModelType modelType) -> bool {
        return modelType != ModelTypeGround;
    })
    | std::views::transform([modelView, selectedModelType, weakSelf](ModelType modelType) -> UIAction * {
        NSString *title = NSStringFromModelType(modelType);
        
        UIAction *action = [UIAction actionWithTitle:title image:nil identifier:title handler:^(__kindof UIAction * _Nonnull action) {
            modelView.modelType = modelType;
            weakSelf.navigationItem.rightBarButtonItem.title = title;
        }];
        
        action.state = (selectedModelType == modelType) ? UIMenuElementStateOn : UIMenuElementStateOff;
        
        return action;
    })
    | std::ranges::to<std::vector<UIAction *>>();
    
    NSArray<UIAction *> *children = [[NSArray alloc] initWithObjects:childrenVec.data() count:childrenVec.size()];
    return [children autorelease];
}

@end
