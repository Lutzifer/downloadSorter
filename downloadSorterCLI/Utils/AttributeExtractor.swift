//
//  AttributeExtractor.swift
//  downloadSorter
//
//  Created by Wolfgang Lutz on 02.08.17.
//  Copyright © 2017 Number 42. All rights reserved.
//

import Foundation

struct AttributeExtractor {
  static func getWhereFromsFromFile(at path: String) -> [String] {
    let item: MDItem? = MDItemCreate(kCFAllocatorDefault, path as CFString)
    let list: CFArray = MDItemCopyAttributeNames(item)
    let resDict: [AnyHashable: Any]? = (MDItemCopyAttributes(item, list) as? [AnyHashable: Any])
    return resDict?["kMDItemWhereFroms"] as? [String] ?? [String]()
  }
}
