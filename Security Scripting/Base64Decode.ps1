function Base64Decode($s) {
    $i = 0
    $base64 = $decoded = ''
    $base64chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    # Replace padding with "A" characters for the decoder to work and save the length of the padding to be dropped from the end later
    if ($s.substring($s.length - 2,2) -like "==") {
        $s = $s.substring(0, $s.length - 2) + "AA"
        $padd = 2
        }
    elseif ($s.substring($s.length - 1,1) -like "=") {
        $s = $s.substring(0, $s.length - 1) + "A"
        $padd = 1
    }
    # Take 4 characters at a time
    while ($i -lt $s.length) {
        $d = 0
        
        for ($j=0; $j -lt 4; $j++) {
            $d += $base64chars.indexof($s[$i]) -shl (18 - $j * 6)
            $i++
            }
        # Convert the 4 chars back to ASCII
        $decoded += [char](($d -shr 16) -band 255)
        $decoded += [char](($d -shr 8) -band 255)
        $decoded += [char]($d -band 255)
    }
    # Remove padding
    $decoded = $decoded.substring(0, $decoded.length - $padd)
    # Return the Base64 encoded result
    return $decoded
    }