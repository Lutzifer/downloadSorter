//
//  String+Path.swift
//  downloadSorter
//
//  Created by Wolfgang Lutz on 02.08.17.
//  Copyright © 2017 Number 42. All rights reserved.
//

import Foundation

extension String {
  static func path(from components: [String]) -> String {
    return components.joined(separator: "/")
  }
}
