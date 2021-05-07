//
//  main.swift
//  MediaInfoSettingsXPC
//
//  Created by Sbarex on 06/05/21.
//  Copyright © 2021 sbarex. All rights reserved.
//

import Foundation

// Create the delegate for the service.
let delegate = MediaInfoSettingsXPCDelegate()
// Set up the one NSXPCListener for this service. It will handle all incoming connections.
let listener = NSXPCListener.service()
listener.delegate = delegate
// Resuming the serviceListener starts this service. This method does not return.
listener.resume()
