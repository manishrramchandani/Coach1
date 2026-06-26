//  IntakeOnboardingView.swift
//  CoachOS — Features/Auth
//
//  CALLOUT: Implements FR-2.2 (client accepts invite + completes intake on iOS).
//  Designed as short steps, not one dense screen (design spec SS-5). Collects unit
//  preference FIRST so weight/height inputs are labeled correctly. On success the
//  AppState session is set and RootView swaps to the main app.

import SwiftUI

struct IntakeOnboardingView: View {
    @EnvironmentObject var state: AppState

    // Form fields (FR-2.2 intake: goal, height, start weight, units, DOB)
    @State private var unitPref: UnitPreference = .metric
    @State private var goal = ""
    @State private var heightText = ""
    @State private var weightText = ""
    @State private var dob = Calendar.current.date(byAdding: .year, value: -30, to: Date())!
    @State private var password = ""
    @State private var loading = false
    @State private var error: String?

    var body: some View {
        ZStack {
            AppColor.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: Space.l) {
                    // Header — warm welcome (microcopy guidance §8)
                    Text("Welcome to CoachOS").font(AppFont.display).foregroundColor(AppColor.ink)
                    Text("Let's set up your account. This takes under a minute.")
                        .font(AppFont.body).foregroundColor(AppColor.muted)

                    // CALLOUT: Units toggle drives the labels below — pick before entering numbers.
                    Card {
                        VStack(alignment: .leading, spacing: Space.s) {
                            SectionHeader(title: "Units")
                            Picker("Units", selection: $unitPref) {
                                Text("Metric (kg/cm)").tag(UnitPreference.metric)
                                Text("Imperial (lb/in)").tag(UnitPreference.imperial)
                            }.pickerStyle(.segmented)
                        }
                    }

                    Card {
                        VStack(alignment: .leading, spacing: Space.m) {
                            SectionHeader(title: "About you")
                            labeledField("Your goal", text: $goal, placeholder: "e.g. Lose fat, build a habit")
                            labeledField("Height (\(unitPref.heightLabel))", text: $heightText, keyboard: .decimalPad)
                            labeledField("Starting weight (\(unitPref.weightLabel))", text: $weightText, keyboard: .decimalPad)
                            VStack(alignment: .leading, spacing: Space.xs) {
                                Text("Date of birth").font(AppFont.caption).foregroundColor(AppColor.muted)
                                DatePicker("", selection: $dob, displayedComponents: .date).labelsHidden()
                            }
                            SecureField("Create a password", text: $password)
                                .textFieldStyle(.roundedBorder)
                        }
                    }

                    if let error { Text(error).font(AppFont.caption).foregroundColor(AppColor.danger) }

                    PrimaryButton(title: "Start coaching", loading: loading,
                                  disabled: !isValid) { Task { await submit() } }
                }
                .padding(Space.l)
            }
        }
    }

    // CALLOUT: Simple client-side validation mirrors server rules (password ≥8, fields present).
    private var isValid: Bool {
        !goal.isEmpty && Double(heightText) != nil && Double(weightText) != nil && password.count >= 8
    }

    private func submit() async {
        loading = true; error = nil
        do {
            // Convert entered display values → base metric for storage (FR-6).
            let intake = IntakePayload(
                goal: goal, dob: dob,
                heightValue: Units.storeHeight(value: Double(heightText) ?? 0, from: unitPref),
                startWeightValue: Units.storeWeight(value: Double(weightText) ?? 0, from: unitPref),
                unitPref: unitPref)
            let s = try await state.api.acceptInvite(token: "demo-token", password: password, intake: intake)
            state.session = s
        } catch {
            self.error = error.localizedDescription
        }
        loading = false
    }

    @ViewBuilder
    private func labeledField(_ label: String, text: Binding<String>,
                              placeholder: String = "", keyboard: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: Space.xs) {
            Text(label).font(AppFont.caption).foregroundColor(AppColor.muted)
            TextField(placeholder, text: text).textFieldStyle(.roundedBorder).keyboardType(keyboard)
        }
    }
}
