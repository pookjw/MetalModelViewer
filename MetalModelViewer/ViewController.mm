//
//  ViewController.mm
//  MetalModelViewer
//
//  Created by Jinwoo Kim on 9/4/24.
//

#import "ViewController.h"
#import "ModelView.h"

@interface ViewController ()
@end

@implementation ViewController

- (void)loadView {
    ModelView *modelView = [ModelView new];
    self.view = modelView;
    [modelView release];
}

@end
