//
//  ReportScreen.swift
//  foundit
//
//  Created by Aryan Tandon on 3/24/26.
//

import SwiftUI

struct ReportScreen: View {
    @EnvironmentObject var postViewModel: PostViewModel
    
    var body: some View {
        PostItemView()
            .environmentObject(postViewModel)
    }
}

#Preview {
    NavigationStack {
        ReportScreen()
            .environmentObject(PostViewModel())
    }
}
