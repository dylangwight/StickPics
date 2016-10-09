//
//  MessagesViewController.swift
//  MessagesExtension
//
//  Created by Dylan Wight on 8/20/16.
//  Copyright © 2016 Dylan Wight. All rights reserved.
//

import UIKit
import Messages

class MessagesViewController: MSMessagesAppViewController {
        
    // MARK: - Conversation Handling
    
    override func willBecomeActive(with conversation: MSConversation) {
        presentViewController(style: presentationStyle)
    }
    
    override func willTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        // Called before the extension transitions to a new presentation style.
        
        // Use this method to prepare for the change in presentation style.
        
        presentViewController(style: presentationStyle)
    }

    
    private func presentViewController(style: MSMessagesAppPresentationStyle) {
        // Called when the extension is about to move from the inactive to active state.
        // This will happen when the extension is about to present UI.
        
        // Use this method to configure the extension and restore previously stored state.
        
        if let url = activeConversation?.selectedMessage?.url {
            print(url.absoluteString)
        }
        
//        delegate?.dismiss(animated: true, completion: nil)

        let controller: UIViewController
        
        if style == .compact {
            controller = storyboard?.instantiateViewController(withIdentifier: StickPicsCollectionViewController.storyboardIdentifier) as! StickPicsCollectionViewController
        } else {
            controller = (storyboard?.instantiateViewController(withIdentifier: CreateStickPicController.storyboardIdentifier))!
            (controller as! CreateStickPicController).delegate = self
        }
        
        // Remove any existing child controllers.
        for child in childViewControllers {
            child.willMove(toParentViewController: nil)
            child.view.removeFromSuperview()
            child.removeFromParentViewController()
        }
        
        // Embed the new controller.
        addChildViewController(controller)
        
        controller.view.frame = view.bounds
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(controller.view)
        
        controller.view.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        controller.view.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        controller.view.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        controller.view.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        controller.didMove(toParentViewController: self)
    }
}

//    // MARK: Convenience
//
//    fileprivate func composeMessage(with url: URL, caption: String, session: MSSession? = nil) -> MSMessage {
//        var components = URLComponents()
//        components.queryItems = iceCream.queryItems
//        
//        let layout = MSMessageTemplateLayout()
//        layout.image = iceCream.renderSticker(opaque: true)
//        layout.caption = caption
//        
//        let message = MSMessage(session: session ?? MSSession())
//        message.url = components.url!
//        message.layout = layout
//        
//        return message
//    }
//}

extension MessagesViewController: CreateStickPicDelegate {
    func save() {
        requestPresentationStyle(.compact)
    }
}





