import Foundation

enum SnapZiRoute: Hashable {
    case keywordPick
    case characterHub(String)
    case camera(String)
    case photoConfirm(String)
    case photoWordLink(String)
    case segment1(String)
    case segment2(String)
    case segment3Intro(String)
    case segment3Fixed(String)
    case segment3Free(String)
    case characterLibrary
    case photoLibrary
}
