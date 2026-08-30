/*
 * Plain ECMAScript helpers for the City Weather & Time plasmoid.
 * Loaded from QML via: import "js/weather.js" as Weather
 *
 * Uses the two public Open-Meteo endpoints. No API key required.
 *   Geocoding: https://geocoding-api.open-meteo.com/v1/search
 *   Forecast : https://api.open-meteo.com/v1/forecast
 *
 * SPDX-License-Identifier: GPL-2.0-or-later
 */

// ---------- generic JSON request ----------
function requestJson(url, onSuccess, onError) {
    var xhr = new XMLHttpRequest()
    xhr.open("GET", url)
    xhr.timeout = 8000 // milliseconds; Qt Quick XHR supports timeouts

    xhr.onreadystatechange = function () {
        if (xhr.readyState !== XMLHttpRequest.DONE) {
            return
        }
        if (xhr.status >= 200 && xhr.status < 300) {
            var parsed = null
            try {
                parsed = JSON.parse(xhr.responseText)
            } catch (e) {
                onError("invalid")
                return
            }
            if (parsed && parsed.error) {
                // Open-Meteo responds with { "error": true, "reason": "..." } and HTTP 400.
                onError("http")
                return
            }
            onSuccess(parsed)
            return
        }
        onError(xhr.status === 400 ? "invalid" : "network")
    }

    xhr.ontimeout = function () {
        onError("network")
    }
    xhr.onerror = function () {
        onError("network")
    }

    xhr.send()
}

// ---------- geocoding ----------
// Resolves a city name to coordinates and an IANA timezone id.
// onSuccess receives: { name, country, latitude, longitude, timezone }
function fetchGeocode(city, onSuccess, onError) {
    var url = "https://geocoding-api.open-meteo.com/v1/search"
        + "?name=" + encodeURIComponent(city)
        + "&count=1&language=en&format=json"
    requestJson(url, function (data) {
        if (!data || !Array.isArray(data.results) || data.results.length === 0) {
            // A successful HTTP response without a "results" key means no match.
            onError("notfound")
            return
        }
        var r = data.results[0]
        if (typeof r.latitude !== "number" || typeof r.longitude !== "number") {
            onError("invalid")
            return
        }
        onSuccess({
            name: typeof r.name === "string" ? r.name : city,
            country: typeof r.country === "string" ? r.country : "",
            latitude: r.latitude,
            longitude: r.longitude,
            timezone: typeof r.timezone === "string" ? r.timezone : ""
        })
    }, onError)
}

// ---------- forecast ----------
// Always requests Celsius + km/h; the caller converts for display.
// onSuccess receives: { current: { temperature_2m, apparent_temperature,
//                                   relative_humidity_2m, weather_code,
//                                   wind_speed_10m } }
function fetchForecast(latitude, longitude, timezone, onSuccess, onError) {
    var url = "https://api.open-meteo.com/v1/forecast"
        + "?latitude=" + latitude
        + "&longitude=" + longitude
        + "&current=temperature_2m,apparent_temperature,relative_humidity_2m,weather_code,wind_speed_10m"
        + "&temperature_unit=celsius"
        + "&wind_speed_unit=kmh"
        + "&timezone=" + encodeURIComponent(timezone || "GMT")
        + "&forecast_days=1"
    requestJson(url, onSuccess, onError)
}

// ---------- WMO weather interpretation codes ----------
// Codes documented by Open-Meteo (https://open-meteo.com/en/docs).
// Returns a display label; the widget UI is in English by default.
function conditionLabel(code) {
    if (code === 0)                 return "Clear sky"
    if (code === 1)                 return "Mainly clear"
    if (code === 2)                 return "Partly cloudy"
    if (code === 3)                 return "Overcast"
    if (code === 45 || code === 48) return "Fog"
    if (code >= 51 && code <= 57)   return "Drizzle"
    if (code >= 61 && code <= 67)   return "Rain"
    if (code >= 71 && code <= 77)   return "Snowfall"
    if (code >= 80 && code <= 82)   return "Rain showers"
    if (code === 85 || code === 86) return "Snow showers"
    if (code === 95)                return "Thunderstorm"
    if (code === 96 || code === 99) return "Thunderstorm with hail"
    return "Unknown"
}

// Returns the Breeze icon name for a WMO weather code.
function conditionIcon(code) {
    if (code === 0)                 return "weather-clear"
    if (code === 1 || code === 2)   return "weather-few-clouds"
    if (code === 3)                 return "weather-clouds"
    if (code === 45 || code === 48) return "weather-fog"
    if (code >= 51 && code <= 57)   return "weather-showers"
    if (code >= 61 && code <= 67)   return "weather-rain"
    if (code >= 71 && code <= 77)   return "weather-snow"
    if (code >= 80 && code <= 82)   return "weather-showers"
    if (code === 85 || code === 86) return "weather-snow-rain"
    if (code === 95)                return "weather-storm"
    if (code === 96 || code === 99) return "weather-storm"
    return "weather-none-ambivalent"
}

// Reads a possibly-missing numeric value from a nested object.
function number(obj, path, fallback) {
    var v = obj
    for (var i = 0; v !== null && v !== undefined && i < path.length; i = i + 1) {
        v = v[path[i]]
    }
    return (typeof v === "number" && isFinite(v)) ? v : fallback
}