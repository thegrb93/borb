local util = {}
 
function util.drawBody(body, shape)
	love.graphics.setLineWidth( 0.01 )
	love.graphics.polygon("line", body:getWorldPoints(shape:getPoints()))
end

return util
